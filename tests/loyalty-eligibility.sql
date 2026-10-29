begin;
-- Each scenario runs entirely with isolated random accounts.
create temp table loyalty_fixture(name text primary key,id uuid default gen_random_uuid());insert into loyalty_fixture(name)values('owner'),('video'),('unverified');
insert into auth.users(id,email,email_confirmed_at,created_at)select id,id::text||'@example.invalid',case when name='unverified' then null else now() end,now()from loyalty_fixture;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_fixture where name='owner';select public.kiyi_command('bundle');
do $$declare u uuid=auth.uid();f uuid;m text;begin
 select id into m from public.kiyi_vehicle_models where kind='motorcycle'limit 1;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,m,'motorcycle','07 MTR 917');perform kiyi_private.reward_sync(u);
 assert exists(select 1 from public.kiyi_badges where owner=u and code='first_motorcycle');assert (select balance from public.kiyi_wallets where user_id=u)=15;
 -- A customized factory paint alone does not qualify; saving a customization does.
 insert into public.kiyi_vehicle_customizations(vehicle_id,appearance,version)select id,'{"paint":"#123456"}',1 from public.kiyi_vehicles where owner=u on conflict do nothing;
 assert (kiyi_private.reward_metrics(u)->>'customization')::int=0;
 update public.kiyi_vehicle_customizations set version=2 where vehicle_id in(select id from public.kiyi_vehicles where owner=u);perform kiyi_private.reward_sync(u);assert (select balance from public.kiyi_wallets where user_id=u)=20;
 -- Fresh / unverified / unengaged followers cannot mint rewards.
 for n in 1..10 loop
 f=gen_random_uuid();insert into auth.users(id,email,email_confirmed_at,created_at)values(f,f::text||'@example.invalid',now(),now()-interval '8 days');
 insert into public.kiyi_profiles(user_id,username)values(f,'test_'||left(replace(f::text,'-',''),20));
 insert into public.kiyi_follows(follower,target,created_at)values(f,u,now()-interval '2 days');
 if n<=9 then insert into kiyi_private.reward_days select f,current_date-off from generate_series(0,2)dd(off);end if;
 end loop;
 assert (kiyi_private.reward_metrics(u)->>'follower')::int=9;
 select follower into f from public.kiyi_follows where target=u and not exists(select 1 from kiyi_private.reward_days where owner=follower)limit 1;
 insert into kiyi_private.reward_days select f,current_date-off from generate_series(0,2)dd(off);perform kiyi_private.reward_sync(u);
 assert (select balance from public.kiyi_wallets where user_id=u)=30;
 assert exists(select 1 from public.kiyi_badges where owner=u and code='ten_followers');
end$$;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_fixture where name='video';select public.kiyi_command('bundle');
do $$declare u uuid=auth.uid();pid uuid;p text=u::text||'/social/reward-video-fixture';begin
 insert into kiyi_private.media_registry(path,owner,mime,bytes,state)values(p,u,'video/mp4',100,'ready');
 insert into public.kiyi_posts(author,text,media,visibility,created)values(u,'Ödül incelemesindeki video',p,'public',extract(epoch from(now()-interval '2 days'))*1000)returning id into pid;
 assert (kiyi_private.reward_metrics(u)->>'video')::int=0;
 update public.kiyi_reports set status='resolved'where subject_kind='post'and subject_id=pid;
 perform kiyi_private.reward_sync(u);assert (kiyi_private.reward_metrics(u)->>'video')::int=1;assert (select balance from public.kiyi_wallets where user_id=u)=20;
end$$;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_fixture where name='unverified';select public.kiyi_command('bundle');
do $$declare denied bool=false;r jsonb;begin
 r=public.kiyi_command('rewards');assert (r->>'verification_required')::boolean;
 begin perform public.kiyi_command('reward_daily');exception when insufficient_privilege then denied=true;end;assert denied;
 assert (select balance from public.kiyi_wallets where user_id=auth.uid())=0;
end$$;
select 'PASS motorcycle/profile customizations, qualified10followers, moderatedvideo, unverified denial' result;
rollback;
