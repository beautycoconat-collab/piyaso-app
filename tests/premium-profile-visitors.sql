begin;
do $test$
declare owner_id uuid=gen_random_uuid();visitor_id uuid=gen_random_uuid();denied boolean;result jsonb;
begin
 insert into auth.users(id) values(owner_id),(visitor_id);
 perform set_config('request.jwt.claim.sub','',true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_id)::text,true);
 perform public.kiyi_command('profile',jsonb_build_object('username','pv_owner_'||left(replace(owner_id::text,'-',''),15),'searchable',true));
 perform set_config('request.jwt.claims',jsonb_build_object('sub',visitor_id)::text,true);
 perform public.kiyi_command('profile',jsonb_build_object('username','pv_viewer_'||left(replace(visitor_id::text,'-',''),15),'searchable',true));
 perform public.kiyi_command('visit',jsonb_build_object('target',owner_id));
 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_id)::text,true);
 denied=false;begin perform public.kiyi_command('visits','{"premium":true}');exception when sqlstate 'PT402' then denied=true;end;assert denied,'Free account could retrieve identities';
 insert into public.kiyi_entitlements(user_id,premium_until) values(owner_id,now()+interval '1 day') on conflict(user_id) do update set premium_until=excluded.premium_until;
 result=public.kiyi_command('visits');assert jsonb_array_length(result->'visitors')=1,'Premium visitor list failed';assert result->'visitors'->0->>'id'=visitor_id::text,'Wrong visitor identity';
 update public.kiyi_entitlements set premium_until=now()-interval '1 day' where user_id=owner_id;
 denied=false;begin perform public.kiyi_command('visits');exception when sqlstate 'PT402' then denied=true;end;assert denied,'Expired Premium retained visitor access';
 assert not has_table_privilege('authenticated','public.kiyi_visits','SELECT'),'Direct visitor table bypass';
 assert not has_table_privilege('anon','public.kiyi_visits','SELECT'),'Anonymous table bypass';
end
$test$;
rollback;
select 'PASS: Free/forged claims and expired Premium denied; active Premium can read own visitors; no direct table access' as result;
