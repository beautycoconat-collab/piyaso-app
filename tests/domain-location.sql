begin;
insert into auth.users(id,email) values('a1111111-1111-4111-8111-111111111111','kiyi-test-a@example.invalid'),('b2222222-2222-4222-8222-222222222222','kiyi-test-b@example.invalid');
set local role authenticated;
select set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
select public.kiyi_command('profile','{"username":"kiyi_test_b","searchable":true,"profile":{"plate":"07 TST 002"}}');
do $$declare x jsonb;begin
 perform set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
 x=public.kiyi_command('directory','{"plate":"07tst002"}');assert jsonb_array_length(x->'profiles')=0,'Private legacy plate leaked';
 perform set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
end$$;
-- New garages are private by default. Publish only this disposable fixture.
select public.kiyi_command('vehicle_update',jsonb_build_object('vehicle_id',(public.kiyi_command('garage_list')->'vehicles'->0->>'id'),'visibility','public'));
select set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
do $$declare x jsonb;payload jsonb;denied boolean;begin
 x=public.kiyi_command('directory','{"plate":"07tst002"}');assert jsonb_array_length(x->'profiles')=1,'Plate normalization failed';
 perform public.kiyi_command('profile','{"username":"kiyi_test_a","searchable":true,"profile":{"plate":"07 TST 001"}}');
 perform public.kiyi_command('verification','{"plate":"07 TST 001","note":"Test sahiplik açıklaması","consent":true}');
 perform public.kiyi_command('visit','{"target":"b2222222-2222-4222-8222-222222222222"}');
 perform public.kiyi_command('sharing','{"enabled":true}');
 payload=jsonb_build_object('session','c3333333-3333-4333-8333-333333333333','seq',1,'lat',36.86702735,'lng',30.6417432365968,'accuracy',10,'observed_at',(extract(epoch from clock_timestamp())*1000)::bigint);
 x=public.kiyi_command('position',payload);assert x->>'region'='konyaalti','Region check failed';
 perform set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
 x=public.kiyi_command('map','{"west":30.5,"east":30.8,"south":36.7,"north":37,"zoom":18,"region":"all"}');assert jsonb_array_length(x->'people')=1,'Location absent';
 denied=false;begin x=public.kiyi_command('visits');exception when sqlstate 'PT402' then denied=true;end;assert denied,'Free profile visitor access allowed';
 perform set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
 perform public.kiyi_command('sharing','{"ghost":true}');
 perform set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
 x=public.kiyi_command('map','{"west":30.5,"east":30.8,"south":36.7,"north":37,"zoom":18,"region":"all"}');assert x->'people'->0->>'username'='hayalet','Ghost name leak';assert x->'people'->0->>'id'<>'a1111111-1111-4111-8111-111111111111','Ghost identity leak';
 perform set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
 perform public.kiyi_command('sharing','{"visibility":"approved"}');
 perform set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
 x=public.kiyi_command('map','{"west":30.5,"east":30.8,"south":36.7,"north":37,"zoom":18,"region":"all"}');assert jsonb_array_length(x->'people')=0,'Approved-only location leaked';
 perform set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
 denied=false;begin perform public.kiyi_command('position',payload||'{"seq":2}');exception when raise_exception then denied=true;end;assert denied,'GPS rate limit bypass';
end $$;
reset role;
-- Advance only this transaction fixture; do not sleep or relax production limits.
update public.kiyi_positions set received_at=now()-interval '5 seconds' where user_id='a1111111-1111-4111-8111-111111111111';
set local role authenticated;
do $$declare x jsonb;denied boolean;payload jsonb=jsonb_build_object('session','c3333333-3333-4333-8333-333333333333','seq',1,'lat',36.86702735,'lng',30.6417432365968,'accuracy',10,'observed_at',(extract(epoch from clock_timestamp())*1000)::bigint);begin
 x=public.kiyi_command('position',payload||'{"seq":2,"lat":38.4,"lng":27.1}');assert not (x->>'inside')::boolean,'Izmir enabled';
 perform public.kiyi_command('sharing','{"enabled":false}');
 denied=false;begin perform public.kiyi_command('position',payload);exception when raise_exception then denied=true;end;assert denied,'Off sharing accepted GPS';
end $$;
reset role;
select 'PASS: normalized search, verification, visits, Antalya geofence, ghost masking, approved access, disabled GPS, Izmir excluded' as test_result;
rollback;
