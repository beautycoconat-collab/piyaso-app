begin;
-- Preserve every existing award/balance. New pending referrals qualify by owned plate,
-- not by three activity days. Registration still requires confirmed non-anonymous Auth.
create table kiyi_private.reward_invite_plates(
 plate_hash text primary key, invitee uuid references auth.users on delete set null,
 claimed_at timestamptz not null default now());
alter table kiyi_private.reward_invite_plates enable row level security;
revoke all on kiyi_private.reward_invite_plates from public,anon,authenticated;
-- Historical paid referrals reserve their known plate too, without replaying payments.
insert into kiyi_private.reward_invite_plates(plate_hash,invitee)
 select distinct on(v.plate_hash) v.plate_hash,i.invitee from kiyi_private.reward_invites i
 join kiyi_private.reward_vehicle_plates v on v.owner=i.invitee where i.paid_at is not null
 order by v.plate_hash,i.paid_at,i.invitee on conflict do nothing;
create function kiyi_private.reward_invite_plate(u uuid) returns text
 language sql stable security definer set search_path='' as $$
 select md5(v.plate_key) from public.kiyi_vehicles v
 where v.owner=u and v.deleted_at is null and v.model_id is not null and nullif(v.plate_key,'') is not null
 and not exists(select 1 from kiyi_private.reward_vehicle_plates h where h.plate_hash=md5(v.plate_key) and h.owner<>u)
 and not exists(select 1 from kiyi_private.reward_invite_plates h where h.plate_hash=md5(v.plate_key) and h.invitee is distinct from u)
 order by v.created_at,v.id limit 1
$$;
revoke all on function kiyi_private.reward_invite_plate(uuid) from public,anon,authenticated;
-- Save exact previous definitions for a non-destructive rollback.
insert into kiyi_private.reward_backup(name,definition)
 select 'plate_v1:'||p.proname,pg_get_functiondef(p.oid) from pg_proc p
 where p.pronamespace='kiyi_private'::regnamespace and p.proname in('reward_settle','reward_process_invites','reward_command','badge_metrics');
create or replace function kiyi_private.reward_settle(u uuid) returns void language plpgsql security definer set search_path='' as $$
declare r record;n int;coins int;cap int;plate_hash_value text;reserved uuid;
 month_start timestamptz=date_trunc('month',now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul';begin
 if not kiyi_private.account_active(u) then return;end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 select referral_amount,monthly_cap into coins,cap from kiyi_private.reward_settings;
 select count(*) into n from kiyi_private.reward_awards where owner=u and award_key like 'invite:%' and not legacy and created_at>=month_start;
 for r in select * from kiyi_private.reward_invites where referrer=u and paid_at is null order by created_at,invitee loop
 exit when n>=cap;
 if not kiyi_private.account_active(r.invitee) or kiyi_private.blocked(u,r.invitee)
 or not exists(select 1 from auth.users where id=r.invitee and email_confirmed_at is not null and not coalesce(is_anonymous,false))
 or exists(select 1 from kiyi_private.badge_invalidations where kind='invite' and subject=r.invitee) then continue;end if;
 plate_hash_value=kiyi_private.reward_invite_plate(r.invitee);
 if plate_hash_value is null then continue;end if;
 insert into kiyi_private.reward_invite_plates(plate_hash,invitee)values(plate_hash_value,r.invitee)on conflict do nothing;
 select invitee into reserved from kiyi_private.reward_invite_plates where plate_hash=plate_hash_value;
 if reserved is distinct from r.invitee then continue;end if;
 if kiyi_private.reward_pay(u,'invite:'||r.identity_key,coins) then n=n+1;end if;
 update kiyi_private.reward_invites set paid_at=now() where invitee=r.invitee;
 end loop;
end$$;
-- Change the existing guarded dashboard, scheduler and badge calculations in place.
do $$declare d text;old text;replacement text;begin
 old='(select count(*)from kiyi_private.reward_days d where d.owner=i.invitee and d.day>=(i.created_at at time zone ''Europe/Istanbul'')::date)>=3';
 d=pg_get_functiondef('kiyi_private.reward_process_invites()'::regprocedure);
 if strpos(d,old)=0 then raise exception 'Scheduler definition changed';end if;
 execute replace(d,old,'kiyi_private.reward_invite_plate(i.invitee) is not null');
 d=pg_get_functiondef('kiyi_private.badge_metrics(uuid)'::regprocedure);
 if strpos(d,old)=0 then raise exception 'Badge metrics definition changed';end if;
 execute replace(d,old,'kiyi_private.reward_invite_plate(i.invitee) is not null');
 d=pg_get_functiondef('kiyi_private.reward_command(text,jsonb)'::regprocedure);
 old='if exists(select 1 from kiyi_private.reward_days where owner=u) then raise exception ''Davet kodunu ilk aktif kullanımından önce ekle.'' using errcode=''22023'';end if;';
 if strpos(d,old)=0 then raise exception 'Referral binding definition changed';end if;
 d=replace(d,old,'-- New users may bind within the existing seven-day window, including after plate entry.');
 old='''days'',q.days,''paid''';replacement='''days'',q.days,''plate_added'',q.plate_added,''paid''';
 if strpos(d,old)=0 then raise exception 'Referral dashboard definition changed';end if;d=replace(d,old,replacement);
 old='n,created_at,paid_at,(select count(*)';replacement='n,created_at,paid_at,(kiyi_private.reward_invite_plate(i.invitee) is not null) plate_added,(select count(*)';
 if strpos(d,old)=0 then raise exception 'Referral dashboard query changed';end if;d=replace(d,old,replacement);execute d;
end$$;
revoke all on function kiyi_private.reward_settle(uuid),kiyi_private.reward_process_invites(),kiyi_private.reward_command(text,jsonb),kiyi_private.badge_metrics(uuid) from public,anon,authenticated;
commit;
