-- Disposable random users only; every row and schema fixture rolls back.
begin;
create temp table reward_test_users(name text primary key,id uuid not null default gen_random_uuid());
insert into reward_test_users(name)values('daily'),('referrer'),('invitee'),('garage'),('posts');
insert into auth.users(id,email,email_confirmed_at,created_at)select id,replace(id::text,'-','')||'@example.invalid',now(),case when name='referrer' then now()-interval '1 minute' else now() end from reward_test_users;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true) from reward_test_users where name='daily';
select public.kiyi_command('bundle');
do $$declare r jsonb;n int;today date=(now()at time zone 'Europe/Istanbul')::date;begin
 assert (select sum(x)from kiyi_private.reward_settings,unnest(daily)x)=320;
 assert (select sum(daily[i])from kiyi_private.reward_settings,generate_series(1,10)i)=100;
 assert (select sum(daily[i])from kiyi_private.reward_settings,generate_series(11,20)i)=100;
 assert (select sum(daily[i])from kiyi_private.reward_settings,generate_series(21,30)i)=120;
 r=public.kiyi_command('reward_daily','{"amount":999999,"owner":"00000000-0000-0000-0000-000000000000"}');assert (r->>'amount')::int=5;
 r=public.kiyi_command('reward_daily');assert (r->>'already_claimed')::boolean;
 assert (select balance from public.kiyi_wallets where user_id=auth.uid())=5;
 assert (select count(*)from public.kiyi_ledger where owner=auth.uid()and kind='reward')=1;
 assert kiyi_private.reward_day_next(today-2,29,today)=1;
 assert kiyi_private.reward_day_next(today-1,30,today)=31;
 assert kiyi_private.reward_day_next(today,7,today)=7;
 assert (('2026-10-26 21:01:00+00'::timestamptz at time zone 'Europe/Istanbul')::date)='2026-10-27'::date;
end$$;
-- Fresh user per milestone: no test clock or client timestamp accepted in production.
do $$declare milestone int;u uuid;r jsonb;expected int;begin foreach milestone in array array[7,10,14,21,30,31]loop
 u=gen_random_uuid();insert into auth.users(id,email,email_confirmed_at,created_at)values(u,u::text||'@example.invalid',now(),now());
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u)::text,true);perform public.kiyi_command('bundle');
 insert into kiyi_private.reward_daily values(u,(now()at time zone 'Europe/Istanbul')::date-1,milestone-1);
 r=public.kiyi_command('reward_daily');expected=case milestone when 7 then 30 when 10 then 20 when 14 then 30 when 21 then 30 when 30 then 40 else 5 end;
 assert (r->>'amount')::int=expected,'Milestone amount';assert (r->>'day')::int=(milestone-1)%30+1;
end loop;end$$;
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
 perform kiyi_private.reward_settle(parent);perform kiyi_private.reward_settle(parent);
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
 end loop;perform kiyi_private.reward_settle(parent);
 assert (select count(*)from public.kiyi_ledger where owner=parent and reference like 'invite:%')=5;
 assert (select sum(amount)from public.kiyi_ledger where owner=parent and reference like 'invite:%')=375;
 assert (select count(*)from kiyi_private.reward_invites where referrer=parent and paid_at is null)=1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',parent)::text,true);
 begin perform public.kiyi_command('reward_referral',jsonb_build_object('code',code));raise exception 'Self invite accepted';exception when invalid_parameter_value then null;end;
end$$;
-- Lifetime unique plates: delete / recreate does not add a second garage reward.
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from reward_test_users where name='garage';select public.kiyi_command('bundle');
do $$declare model text;u uuid=auth.uid();before_balance bigint;begin
 select id into model from public.kiyi_vehicle_models where kind='car' and ready limit 1;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,model,'car','07 RWD 901');perform kiyi_private.reward_sync(u);
 assert exists(select 1 from public.kiyi_badges where owner=u and code='first_car');
 select balance into before_balance from public.kiyi_wallets where user_id=u;assert before_balance=15;
 delete from public.kiyi_vehicles where owner=u;insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,model,'car','07 RWD 901');perform kiyi_private.reward_sync(u);
 assert (select balance from public.kiyi_wallets where user_id=u)=before_balance;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,model,'car','07 RWD 902'),(u,model,'car','07 RWD 903');perform kiyi_private.reward_sync(u);perform kiyi_private.reward_sync(u);
 assert (select balance from public.kiyi_wallets where user_id=u)=65;
 assert (select count(*)from kiyi_private.reward_vehicles where owner=u)=3;
end$$;
-- Qualified posts: hidden, identical or pending-review content does not count.
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from reward_test_users where name='posts';select public.kiyi_command('bundle');
do $$declare u uuid=auth.uid();pid uuid;begin
 insert into public.kiyi_posts(author,text,created,visibility)select u,'Aynı kopyalanmış içerik',extract(epoch from(now()-interval '2 days'))*1000,'public' from generate_series(1,10);
 assert (kiyi_private.reward_metrics(u)->>'post')::int=1;
 insert into public.kiyi_posts(author,text,created,hidden,visibility)values(u,'Bu içerik moderasyonla kaldırılmıştır',extract(epoch from(now()-interval '2 days'))*1000,true,'public');
 assert (kiyi_private.reward_metrics(u)->>'post')::int=1;
 insert into public.kiyi_posts(author,text,created,visibility)values(u,'İnceleme bekleyen geçerli bir yazı',extract(epoch from(now()-interval '2 days'))*1000,'public')returning id into pid;
 insert into public.kiyi_reports(reporter,target,reason,subject_kind,subject_id)values(u,u,'Spam','post',pid);
 assert (kiyi_private.reward_metrics(u)->>'post')::int=1;
 perform kiyi_private.reward_sync(u);assert (select balance from public.kiyi_wallets where user_id=u)=10;
 insert into public.kiyi_posts(author,text,created,visibility)select u,'Sahil yolundaki güzel yolculuk numara '||i,extract(epoch from(now()-interval '2 days'))*1000,'public' from generate_series(1,24)i;
 perform kiyi_private.reward_sync(u);assert (select balance from public.kiyi_wallets where user_id=u)=50;
end$$;
-- Direct writes/foreign reads/admin settings are denied even with an authenticated role.
set local role authenticated;
do $$declare denied boolean=false;r jsonb;begin
 begin perform * from kiyi_private.reward_awards;exception when insufficient_privilege then denied=true;end;assert denied;
 denied=false;begin perform kiyi_private.reward_pay(auth.uid(),'daily:fake',500);exception when insufficient_privilege then denied=true;end;assert denied;
 denied=false;begin perform public.kiyi_command('reward_admin','{"referral_amount":500,"reason":"unauthorized test"}');exception when others then denied=true;end;assert denied;
 r=public.kiyi_command('rewards',jsonb_build_object('target',(select '00000000-0000-0000-0000-000000000000')));assert (r->>'balance')::int=50;
end$$;
reset role;
-- A failed ledger write rolls back both award and wallet changes.
create function pg_temp.fail_reward() returns trigger language plpgsql as $$begin if new.reference='daily:'||(now()at time zone 'Europe/Istanbul')::date::text then raise exception 'fixture ledger failure';end if;return new;end$$;
create trigger reward_test_failure before insert on public.kiyi_ledger for each row execute function pg_temp.fail_reward();
do $$declare old bigint;denied boolean=false;begin
 select balance into old from public.kiyi_wallets where user_id=auth.uid();
 begin perform public.kiyi_command('reward_daily');exception when others then denied=true;end;
 assert denied;assert (select balance from public.kiyi_wallets where user_id=auth.uid())=old;
 assert not exists(select 1 from kiyi_private.reward_awards where owner=auth.uid()and award_key='daily:'||(now()at time zone 'Europe/Istanbul')::date::text);
end$$;
select 'PASS: calendar totals, daily replay/forgery, milestones, timezone, reset/cycle, referral replay/self/cap, garage replay, content qualification, RLS/admin denial, atomic rollback' as tests;
rollback;
