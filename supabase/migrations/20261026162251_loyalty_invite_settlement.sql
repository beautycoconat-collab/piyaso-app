begin;
-- Avoid acquiring another user's wallet lock inside an interactive domain command.
insert into kiyi_private.reward_backup(name,definition)values('reward_activity',pg_get_functiondef('kiyi_private.reward_activity(uuid)'::regprocedure));
create or replace function kiyi_private.reward_activity(u uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if not kiyi_private.account_active(u) or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null) then return;end if;
 begin perform kiyi_private.reward_identity_for(u);exception when insufficient_privilege then return;end;
 insert into kiyi_private.reward_days values(u,(now()at time zone 'Europe/Istanbul')::date)on conflict do nothing;
 perform kiyi_private.reward_sync(u);
end$$;
create index reward_invites_pending on kiyi_private.reward_invites(referrer,created_at)where paid_at is null;
create function kiyi_private.reward_process_invites() returns int language plpgsql security definer set search_path='' as $$
declare u uuid;n int=0;begin
 for u in select distinct i.referrer from kiyi_private.reward_invites i cross join kiyi_private.reward_settings c where i.paid_at is null
 and (select count(*)from kiyi_private.reward_days d where d.owner=i.invitee and d.day>=(i.created_at at time zone 'Europe/Istanbul')::date)>=3
 and (select count(*)from kiyi_private.reward_awards a where a.owner=i.referrer and a.award_key like 'invite:%'and not a.legacy and a.created_at>=date_trunc('month',now()at time zone 'Europe/Istanbul')at time zone 'Europe/Istanbul')<c.monthly_cap
 order by i.referrer limit 100 loop
 perform kiyi_private.reward_settle(u);n=n+1;
 end loop;return n;
end$$;
revoke all on function kiyi_private.reward_activity(uuid),kiyi_private.reward_process_invites() from public,anon,authenticated;
select cron.schedule('kiyi-reward-invites','*/5 * * * *','select kiyi_private.reward_process_invites()');
commit;
