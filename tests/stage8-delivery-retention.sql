begin;
insert into auth.users(id,email,email_confirmed_at) values('a9999999-9999-4999-8999-999999999993','retention@example.invalid',now());
select set_config('request.jwt.claims','{"sub":"a9999999-9999-4999-8999-999999999993"}',true);
select public.kiyi_command('bundle');
select public.kiyi_command('delivery_settings','{"email":true,"push":true}');
insert into public.kiyi_devices(owner,device_id,platform,push_token,enabled) values(auth.uid(),'a9999999-9999-4999-8999-999999999993','ios','fixture-token',true);
insert into public.kiyi_notifications(recipient,sender,kind,created) values(auth.uid(),auth.uid(),'admin',1);
do $$declare j kiyi_private.delivery_outbox;begin
 select * into j from kiyi_private.delivery_outbox where recipient=auth.uid() and channel='push';assert not kiyi_private.delivery_allowed(j),'Unbound device eligible';
 insert into auth.sessions(id,user_id) values('c9999999-9999-4999-8999-999999999993',auth.uid());
 update public.kiyi_devices set session_id='c9999999-9999-4999-8999-999999999993' where owner=auth.uid();
 assert kiyi_private.delivery_allowed(j),'Bound device ineligible';
 update auth.sessions set not_after=now()-interval '1 second' where id='c9999999-9999-4999-8999-999999999993';
 assert not kiyi_private.delivery_allowed(j),'Revoked device eligible';
end$$;
insert into kiyi_private.delivery_outbox(recipient,channel,kind,event_key,state,expires_at) values(auth.uid(),'email','admin','old-fixture','retry',now()-interval '32 days'),(auth.uid(),'email','admin','expired-fixture','queued',now()-interval '1 hour');
select kiyi_private.delivery_maintenance();
do $$begin
 assert not exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and event_key='old-fixture');
 assert exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and event_key='expired-fixture' and state='cancelled');
 assert exists(select 1 from public.kiyi_notifications where recipient=auth.uid());
 assert not has_function_privilege('authenticated','kiyi_private.delivery_maintenance()','execute');
end$$;
update kiyi_private.ops_settings set value='true' where key='delivery_email_enabled';
insert into kiyi_private.delivery_outbox(recipient,channel,kind,event_key,state,attempts) values(auth.uid(),'email','admin','attempts-fixture','retry',5);
do $$declare r jsonb;j jsonb;begin
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');
 assert exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and event_key='attempts-fixture' and state='failed'),'Attempt limit did not fail';
 j=r->'jobs'->0;assert j is not null,'No active email fixture';
 update kiyi_private.delivery_outbox set expires_at=now()-interval '1 second' where id=(j->>'id')::uuid;
 r=public.kiyi_delivery_worker('resolve',j);assert r->>'status'='cancelled','Expired lease resolved for send';
end$$;
select 'PASS session-bound devices, logout revocation, expiry, metadata retention and preserved inbox' result;
rollback;
