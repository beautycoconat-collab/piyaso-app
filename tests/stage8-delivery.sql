-- Owner-only fixture test; all rows and delivery flags roll back. No provider call.
begin;
insert into auth.users(id,email,email_confirmed_at) values('a9999999-9999-4999-8999-999999999991','a-delivery@example.invalid',now()),('b9999999-9999-4999-8999-999999999991','b-delivery@example.invalid',now());
select set_config('request.jwt.claims','{"sub":"b9999999-9999-4999-8999-999999999991"}',true);
select public.kiyi_command('bundle');
select set_config('request.jwt.claims','{"sub":"a9999999-9999-4999-8999-999999999991"}',true);
select public.kiyi_command('bundle');
set local role authenticated;
do $$declare r jsonb;denied boolean=false;begin
 r=public.kiyi_command('delivery_settings','{}');assert not(r->'preferences'->>'email')::boolean and not(r->'preferences'->>'push')::boolean,'Default consent';
 r=public.kiyi_command('delivery_settings','{"email":true,"events":{"follow":true}}');assert (r->'preferences'->>'email')::boolean;
 begin perform public.kiyi_command('delivery_settings','{"owner":"b9999999-9999-4999-8999-999999999991"}');exception when invalid_parameter_value then denied=true;end;assert denied,'Spoofed preferences';
 denied=false;begin perform public.kiyi_delivery_worker('claim','{"channel":"email"}');exception when insufficient_privilege then denied=true;end;assert denied,'User worker access';
end$$;
reset role;
insert into public.kiyi_notifications(recipient,sender,kind,created) values('a9999999-9999-4999-8999-999999999991','b9999999-9999-4999-8999-999999999991','follow',1);
do $$declare r jsonb;j jsonb;old_lease text;denied boolean=false;begin
 assert (select count(*) from kiyi_private.delivery_outbox where recipient=auth.uid())=1,'Outbox enqueue/default push';
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');assert r->>'status'='pending_configuration' and r->'jobs'='[]'::jsonb,'Unconfigured send';
 update kiyi_private.ops_settings set value='true' where key='delivery_email_enabled';
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');j=r->'jobs'->0;assert j is not null,'No claim';old_lease=j->>'lease';
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');assert r->'jobs'='[]'::jsonb,'Duplicate lease';
 update kiyi_private.delivery_outbox set lease_until=now()-interval '1 second' where id=(j->>'id')::uuid;
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');j=r->'jobs'->0;assert j->>'lease'<>old_lease,'Expired lease not rotated';
 begin perform public.kiyi_delivery_worker('ack',jsonb_build_object('id',j->>'id','lease',old_lease,'outcome','accepted'));exception when insufficient_privilege then denied=true;end;assert denied,'Stale lease ack';
 r=public.kiyi_delivery_worker('resolve',j);assert r->>'status'='ready' and r->>'email'='a-delivery@example.invalid','Resolve';
 insert into public.kiyi_blocks(owner,target) values('a9999999-9999-4999-8999-999999999991','b9999999-9999-4999-8999-999999999991');
 r=public.kiyi_delivery_worker('resolve',j);assert r->>'status'='cancelled','Block after claim leaked';
 delete from public.kiyi_blocks where owner=auth.uid();
end$$;
insert into public.kiyi_notifications(recipient,sender,kind,created) values('a9999999-9999-4999-8999-999999999991','b9999999-9999-4999-8999-999999999991','follow',2);
do $$declare r jsonb;j jsonb;begin
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');j=r->'jobs'->0;
 perform public.kiyi_delivery_worker('ack',j||'{"outcome":"retry"}');
 assert exists(select 1 from kiyi_private.delivery_outbox where id=(j->>'id')::uuid and state='retry' and available_at>now()),'Backoff missing';
 r=public.kiyi_delivery_worker('claim','{"channel":"email"}');assert r->'jobs'='[]'::jsonb,'Backoff bypass';
 perform public.kiyi_command('delivery_settings','{"email":false}');
 assert not exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and state in ('retry','leased','queued','waiting_configuration')),'Revocation missing';
 assert not has_table_privilege('authenticated','kiyi_private.delivery_outbox','select'),'Queue leaked';
end$$;
select 'PASS opt-in, transactional enqueue, config gate, leases, stale ACK rejection, resolve-time block, backoff, revocation, private worker' result;
rollback;
