-- Non-destructive fallback. Deploy the preceding frontend source together with this.
-- Use apply_migration; all badge/preference/report/notification data is retained.
begin;
alter table public.kiyi_follows disable trigger stage6_follow;
alter table public.kiyi_likes disable trigger stage6_like;
alter table public.kiyi_comments disable trigger stage6_comment;
alter table public.kiyi_posts disable trigger stage6_post;
alter table public.kiyi_vehicles disable trigger stage6_vehicle;
alter table public.kiyi_entitlements disable trigger stage6_entitlement;
alter function kiyi_private.command(text,jsonb) rename to command_stage6_disabled;
revoke all on function kiyi_private.command_stage6_disabled(text,jsonb) from public,anon,authenticated;
-- Keep the historical Stage 6 records, but an older client must receive only
-- its supported legacy notification kinds. All business actions use Stage 5.
create function kiyi_private.command(action text,payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb;
begin
 r=kiyi_private.command_stage5(action,payload);
 if action='bundle' then
  r=r||jsonb_build_object('notifications',coalesce((select jsonb_agg(n) from jsonb_array_elements(r->'notifications')n where n->>'event_key' is null),'[]'));
 end if;
 return r;
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
do $$begin execute (select definition from kiyi_private.stage6_admin_backup limit 1);end$$;
notify pgrst,'reload schema';
commit;
