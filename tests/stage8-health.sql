begin;
insert into kiyi_private.ops_events(kind,code,created_at) select 'client','api_error',now() from generate_series(1,10);
insert into kiyi_private.ops_events(kind,code,created_at) values('client','offline',now()-interval '31 days'),('test_audit','retain',now()-interval '31 days');
do $$declare n int;begin
 select count(*) into n from kiyi_private.ops_jobs where kind='health_alert';
 perform kiyi_private.health_maintenance();perform kiyi_private.health_maintenance();
 assert (select count(*) from kiyi_private.ops_jobs where kind='health_alert')<=n+1,'Duplicate alert';
 assert exists(select 1 from kiyi_private.ops_jobs where kind='health_alert'),'Missing admin health alert';
 assert exists(select 1 from kiyi_private.ops_events where kind='test_audit' and code='retain'),'Audit data erased';
 assert not exists(select 1 from kiyi_private.ops_events where kind='client' and code='offline' and created_at<now()-interval '30 days'),'Telemetry retention failed';
 assert not has_function_privilege('authenticated','kiyi_private.health_maintenance()','execute'),'Client privileged maintenance';
end$$;
select 'PASS anonymous-only retention, admin queue alert, dedupe and private maintenance' result;
rollback;
