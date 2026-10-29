begin;create temp table reward_test_users(name text primary key,id uuid not null default gen_random_uuid());
insert into reward_test_users(name)values('daily'),('referrer'),('invitee'),('garage'),('posts');
insert into auth.users(id,email,email_confirmed_at,created_at)select id,replace(id::text,'-','')||'@example.invalid',now(),case when name='referrer' then now()-interval '1 minute' else now() end from reward_test_users;
-- New confirmed user, canonical self-invite prevention and idempotent binding.
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from reward_test_users where name='referrer';select public.kiyi_command('bundle');select public.kiyi_command('rewards');
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from reward_test_users where name='invitee';select public.kiyi_command('bundle');
do $$declare code text;r jsonb;parent uuid;begin
 select c.code,c.owner into code,parent from kiyi_private.reward_codes c join reward_test_users t on t.id=c.owner where t.name='referrer';
 r=public.kiyi_command('reward_referral',jsonb_build_object('code',lower(code)));assert (r->>'ok')::boolean;
 r=public.kiyi_command('reward_referral',jsonb_build_object('code',code));assert (r->>'already_bound')::boolean;
 assert not exists(select 1 from public.kiyi_ledger where owner=parent and reference like 'invite:%');
 update kiyi_private.reward_invites set created_at=now()-interval '2 days' where invitee=auth.uid();
 insert into public.kiyi_vehicles(owner,model_id,kind,plate) select auth.uid(),id,'car','07 LYT '||(100000+floor(random()*900000))::int from public.kiyi_vehicle_models where kind='car' order by id limit 1;
 insert into kiyi_private.reward_days select auth.uid(),(now()at time zone 'Europe/Istanbul')::date-offsets.dayoffset from generate_series(0,2)offsets(dayoffset);
 perform kiyi_private.reward_process_invites();perform kiyi_private.reward_process_invites();
 assert (select sum(amount)from public.kiyi_ledger where owner=parent and reference like 'invite:%')=75;
end$$;
-- Six eligible invitations never pay more than five in a Turkish calendar month.
do $$declare child uuid;parent uuid;code text;begin
 select id into parent from reward_test_users where name='referrer';select c.code into code from kiyi_private.reward_codes c where owner=parent;
 for i in 1..5 loop
 child=gen_random_uuid();insert into auth.users(id,email,email_confirmed_at,created_at)values(child,child::text||'@example.invalid',now(),now());perform set_config('request.jwt.claims',jsonb_build_object('sub',child)::text,true);perform public.kiyi_command('bundle');
 perform public.kiyi_command('reward_referral',jsonb_build_object('code',code));
 update kiyi_private.reward_invites set created_at=now()-interval '2 days' where invitee=child;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate) select child,id,'car','07 LYT '||(100000+floor(random()*900000))::int from public.kiyi_vehicle_models where kind='car' order by id limit 1;
 insert into kiyi_private.reward_days select child,(now()at time zone 'Europe/Istanbul')::date-offsets.dayoffset from generate_series(0,2)offsets(dayoffset);
 end loop;perform kiyi_private.reward_process_invites();
 assert (select count(*)from public.kiyi_ledger where owner=parent and reference like 'invite:%')=5;
 assert (select sum(amount)from public.kiyi_ledger where owner=parent and reference like 'invite:%')=375;
 assert (select count(*)from kiyi_private.reward_invites where referrer=parent and paid_at is null)=1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',parent)::text,true);
 begin perform public.kiyi_command('reward_referral',jsonb_build_object('code',code));raise exception 'Self invite accepted';exception when invalid_parameter_value then null;end;
end$$;
select 'PASS scheduled settlement eligibility and monthly cap' result;rollback;