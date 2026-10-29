-- Behavioral rollback only. Keeps every earned credit, ledger entry, badge and audit row.
begin;
select cron.unschedule(jobid) from cron.job where jobname='kiyi-reward-invites';
do $$declare definition text;begin
 select b.definition into definition from kiyi_private.reward_backup b where name='command';
 if definition is null then raise exception 'Reward dispatcher backup missing';end if;
 execute definition;
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
drop trigger if exists reward_vehicle_history on public.kiyi_vehicles;
-- Keep account-erasure cleanup and expanded badge constraint: existing earned data remains valid.
notify pgrst,'reload schema';
commit;
