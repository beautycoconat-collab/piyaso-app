begin;
insert into auth.users(id) values('a8888888-8888-4888-8888-888888888881'),('b8888888-8888-4888-8888-888888888881');
select set_config('request.jwt.claims','{"sub":"a8888888-8888-4888-8888-888888888881"}',true);
select public.kiyi_command('bundle');
set local role authenticated;
do $$declare r jsonb;bad boolean=false;begin
 r=public.kiyi_command('directory','{}');assert r->'profiles'='[]'::jsonb,'Unbounded directory enumeration';
 for i in 1..19 loop perform public.kiyi_command('directory','{"plate":"07TST001"}');end loop;
 begin perform public.kiyi_command('directory','{"plate":"07 TST 001"}');exception when sqlstate 'PT429' then bad=true;end;assert bad,'Search rate bypass';
 perform public.kiyi_command('diagnostic','{"code":"client_error","secret":"must not persist"}');
 bad=false;begin perform public.kiyi_command('diagnostic','{"code":"somebody@example.com"}');exception when invalid_parameter_value then bad=true;end;assert bad,'Arbitrary telemetry accepted';
end$$;
reset role;
do $$begin assert exists(select 1 from kiyi_private.ops_events where kind='client' and code='client_error');assert not has_table_privilege('authenticated','kiyi_private.stage8_backup','select');end$$;
select public.kiyi_command('sharing','{"enabled":true}');
select public.kiyi_command('position',jsonb_build_object('session',gen_random_uuid(),'seq',1,'lat',36.86702735,'lng',30.6417432365968,'heading',123,'accuracy',10,'observed_at',(extract(epoch from clock_timestamp())*1000)::bigint));
select set_config('request.jwt.claims','{"sub":"b8888888-8888-4888-8888-888888888881"}',true);
select public.kiyi_command('bundle');
update public.kiyi_entitlements set premium_until=now()+interval '1 day' where user_id=auth.uid();
set local role authenticated;
do $$declare r jsonb;begin
 r=public.kiyi_command('map','{"west":30.5,"east":30.8,"south":36.7,"north":37,"zoom":18,"region":"all"}');
 assert jsonb_array_length(r->'people')=1,'Shared point missing';
 assert r->'people'->0->'pos'='[36.87,30.64]'::jsonb,'Premium obtained precise position';
 assert r->'people'->0->'heading'='null'::jsonb,'Movement direction leak';
end$$;
select set_config('request.jwt.claims','{"sub":"a8888888-8888-4888-8888-888888888881"}',true);
select public.kiyi_command('sharing','{"enabled":false}');
select set_config('request.jwt.claims','{"sub":"b8888888-8888-4888-8888-888888888881"}',true);
do $$declare r jsonb;begin
 r=public.kiyi_command('map','{"west":30.5,"east":30.8,"south":36.7,"north":37,"zoom":18,"region":"all"}');assert r->'people'='[]'::jsonb,'Premium bypassed stopped sharing';
end$$;
reset role;
select 'PASS bounded search, rate, fixed-code diagnostics, private backup and coarse location' result;
rollback;
