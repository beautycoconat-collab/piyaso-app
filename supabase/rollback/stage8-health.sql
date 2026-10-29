begin;
select cron.unschedule('kiyi-stage8-health');
drop function kiyi_private.health_maintenance();
-- Keep operational records; expired anonymous telemetry cannot be recovered here.
commit;
