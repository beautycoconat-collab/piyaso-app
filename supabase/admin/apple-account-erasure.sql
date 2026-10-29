-- Candidate only; NOT applied to production. Policy is approved separately.
-- Free accounts only. Paid orders/legal holds/shared Auth require policy design.
begin;
create table if not exists kiyi_private.erasure_holds(owner uuid primary key, reason text not null);
alter table kiyi_private.erasure_holds enable row level security;
revoke all on kiyi_private.erasure_holds from public,anon,authenticated,service_role;
create or replace function public.piyaso_erasure_worker(action text,payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=(payload->>'owner')::uuid;r record;n bigint;paths jsonb;
begin
 if auth.jwt()->>'role' is distinct from 'service_role' then raise exception 'SERVICE_ONLY' using errcode='42501';end if;
 if u is null or action not in ('prepare','purge') then raise exception 'INVALID_ERASURE';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi-media-worker',0));
 perform pg_advisory_xact_lock(hashtextextended('piyaso-erase:'||u::text,0));
 if not exists(select 1 from auth.users where id=u) then raise exception 'USER_NOT_FOUND';end if;
 if exists(select 1 from kiyi_private.erasure_holds where owner=u) then raise exception 'RETENTION_REVIEW_REQUIRED';end if;
 if exists(select 1 from public.kiyi_orders where owner=u and (amount_kurus>0 or provider in ('apple','google'))) then raise exception 'PAID_RETENTION_NOT_CONFIGURED';end if;
 -- No assumption that all Auth users belong exclusively to this app. Any
 -- referencing row outside its domain or an administrative history blocks it.
 for r in select ns.nspname sch,cl.relname tab,a.attname col
 from pg_constraint c join pg_class cl on cl.oid=c.conrelid
 join pg_namespace ns on ns.oid=cl.relnamespace
 join pg_attribute a on a.attrelid=cl.oid and a.attnum=c.conkey[1]
 where c.contype='f' and c.confrelid='auth.users'::regclass loop
  if r.sch not in ('auth','storage') and not(r.sch='public' and r.tab like 'kiyi\_%' escape '\') and r.sch<>'kiyi_private'
    or r.sch='kiyi_private' and r.tab in ('admin_memberships','admin_audit','admin_leases','admin_requests','reward_config_audit','ops_announcements','ops_approvals') then
   execute format('select count(*) from %I.%I where %I=$1',r.sch,r.tab,r.col) into n using u;
   if n>0 then raise exception 'SHARED_OR_ADMIN_IDENTITY';end if;
  end if;
 end loop;
 if exists(select 1 from storage.objects where (owner_id=u::text or owner=u) and bucket_id<>'kiyi-media') then raise exception 'SHARED_STORAGE_IDENTITY';end if;
 if action='prepare' then
  if exists(select 1 from kiyi_private.media_registry where owner=u and state='pending') then raise exception 'UPLOAD_IN_PROGRESS';end if;
  if not exists(select 1 from public.kiyi_profiles where user_id=u) then raise exception 'NO_PIYASO_ACCOUNT';end if;
  update public.kiyi_profiles set deleted_at=coalesce(deleted_at,now()),searchable=false where user_id=u;
  update public.kiyi_privacy set sharing=false,approved='{}' where user_id=u;
  delete from public.kiyi_positions where user_id=u;
  -- Includes registered and orphaned objects; exact owner path only.
  select coalesce(jsonb_agg(name),'[]') into paths from (
   select name from storage.objects where bucket_id='kiyi-media' and name like u::text||'/%'
   union select path from kiyi_private.media_registry where owner=u
  ) objects;
  return jsonb_build_object('status','prepared','paths',paths);
 end if;
 if not exists(select 1 from public.kiyi_profiles where user_id=u and deleted_at is not null) then raise exception 'NOT_PREPARED';end if;
 if exists(select 1 from storage.objects where bucket_id='kiyi-media' and name like u::text||'/%') then raise exception 'MEDIA_REMAINS';end if;
 update public.kiyi_privacy set approved=array_remove(approved,u) where u=any(approved);
 -- Clear non-cascading app-specific references. Keep admin/other apps untouched.
 -- User-generated free-form support/sanction data is deleted under the approved
 -- free-account policy; an erasure_hold prevents this until legal review ends.
 delete from kiyi_private.reward_awards where owner=u or identity_key in(select identity_key from kiyi_private.reward_identity where owner=u);
 delete from kiyi_private.reward_invites where invitee=u or referrer=u or identity_key in(select identity_key from kiyi_private.reward_identity where owner=u);
 for r in select ns.nspname sch,cl.relname tab,a.attname col
 from pg_constraint c join pg_class cl on cl.oid=c.conrelid
 join pg_namespace ns on ns.oid=cl.relnamespace
 join pg_attribute a on a.attrelid=cl.oid and a.attnum=c.conkey[1]
 where c.contype='f' and c.confrelid='auth.users'::regclass and ns.nspname='kiyi_private'
 and cl.relname not in ('admin_memberships','admin_audit','admin_leases','admin_requests','reward_config_audit','ops_announcements','ops_approvals') loop
  execute format('delete from %I.%I where %I=$1',r.sch,r.tab,r.col) using u;
 end loop;
 -- Auth Admin DELETE (not this RPC) deletes the real Auth identity; existing
 -- ON DELETE CASCADE handles profile/garage/posts/wallet/gifts/notifications.
 return '{"status":"purged"}'::jsonb;
end$$;
revoke all on function public.piyaso_erasure_worker(text,jsonb) from public,anon,authenticated;
grant execute on function public.piyaso_erasure_worker(text,jsonb) to service_role;
notify pgrst,'reload schema';
commit;
