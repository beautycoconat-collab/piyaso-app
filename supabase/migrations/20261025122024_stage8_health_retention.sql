begin;
create function kiyi_private.health_maintenance() returns jsonb language plpgsql security definer set search_path='' as $$
declare n bigint;removed bigint;begin
 perform pg_advisory_xact_lock(hashtextextended('kiyi-stage8-health',0));
 -- Only new anonymous fixed-code client telemetry; not customer/account/audit data.
 delete from kiyi_private.ops_events where kind='client' and code in ('client_error','api_error','media_error','map_error','notification_error','offline') and created_at<now()-interval '30 days';get diagnostics removed=row_count;
 select count(*) into n from kiyi_private.ops_events where kind='client' and code in ('api_error','media_error','map_error') and created_at>now()-interval '15 minutes';
 if n>=10 and not exists(select 1 from kiyi_private.ops_jobs where kind='health_alert' and created_at>now()-interval '1 hour') then
 insert into kiyi_private.ops_jobs(kind,status,details) values('health_alert','pending',jsonb_build_object('code','CLIENT_FAILURE_THRESHOLD','window_minutes',15,'count',n,'delivery','admin_health_queue'));
 end if;return jsonb_build_object('anonymous_events_expired',removed,'recent_failures',n);
end$$;
revoke all on function kiyi_private.health_maintenance() from public,anon,authenticated;
select cron.schedule('kiyi-stage8-health','*/5 * * * *','select kiyi_private.health_maintenance()');
commit;
