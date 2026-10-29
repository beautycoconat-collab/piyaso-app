begin;
create temp table loyalty_threshold_owner(id uuid default gen_random_uuid());insert into loyalty_threshold_owner default values;
insert into auth.users(id,email,email_confirmed_at,created_at)select id,id::text||'@example.invalid',now(),now()from loyalty_threshold_owner;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_threshold_owner;select public.kiyi_command('bundle');
do $$declare f uuid;u uuid=auth.uid();begin
 for n in 1..100 loop
 f=gen_random_uuid();insert into auth.users(id,email,email_confirmed_at,created_at)values(f,f::text||'@example.invalid',now(),now()-interval '8 days');
 insert into public.kiyi_profiles(user_id,username)values(f,'threshold_'||left(replace(f::text,'-',''),20));
 insert into kiyi_private.reward_days select f,current_date-off from generate_series(0,2)dd(off);
 insert into public.kiyi_follows(follower,target,created_at)values(f,u,now()-interval '2 days');
 end loop;
 perform kiyi_private.reward_sync(u);perform kiyi_private.reward_sync(u);
 assert (kiyi_private.reward_metrics(u)->>'follower')::int=100;
 assert (select balance from public.kiyi_wallets where user_id=u)=35;
 assert (select count(*)from public.kiyi_ledger where owner=u and kind='reward')=2;
 update public.kiyi_profiles set profile='{"ownerName":"Ödül Profil","bio":"Tamamlanmış geçerli bir profil açıklaması","avatar":"https://example.invalid/avatar.jpg"}'where user_id=u;
 perform kiyi_private.reward_sync(u);assert (select balance from public.kiyi_wallets where user_id=u)=45;
end$$;
select 'PASS 10 and100 qualified followers pay only once; profile completion 10' result;rollback;
