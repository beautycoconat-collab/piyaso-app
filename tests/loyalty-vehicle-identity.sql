begin;
create temp table loyalty_identity_owner(id uuid default gen_random_uuid());insert into loyalty_identity_owner default values;
insert into auth.users(id,email,email_confirmed_at,created_at)select id,id::text||'@example.invalid',now(),now()from loyalty_identity_owner;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_identity_owner;select public.kiyi_command('bundle');
do $$declare u uuid=auth.uid();model text;v uuid;begin
 select id into model from public.kiyi_vehicle_models where kind='car'and ready limit 1;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,model,'car','07 RWI 911')returning id into v;
 perform kiyi_private.reward_sync(u);assert (select balance from public.kiyi_wallets where user_id=u)=15;
 update public.kiyi_vehicles set plate='07 RWI 912'where id=v;perform kiyi_private.reward_sync(u);
 assert (select count(*)from kiyi_private.reward_vehicles where owner=u)=1;assert (select balance from public.kiyi_wallets where user_id=u)=15;
 delete from public.kiyi_vehicles where id=v;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(u,model,'car','07 RWI 912')returning id into v;
 update public.kiyi_vehicles set plate='07 RWI 913'where id=v;perform kiyi_private.reward_sync(u);
 assert (select count(*)from kiyi_private.reward_vehicles where owner=u)=1;assert (select balance from public.kiyi_wallets where user_id=u)=15;
 -- Erasure removes personal activity and vehicle identity progress, financial award remains.
 update public.kiyi_profiles set deleted_at=now()where user_id=u;
 assert not exists(select 1 from kiyi_private.reward_vehicle_ids where owner=u);assert not exists(select 1 from kiyi_private.reward_vehicle_plates where owner=u);
 assert exists(select 1 from kiyi_private.reward_awards where owner=u);
end$$;
select 'PASS same vehicle plate edits and recreated plate cannot farm garage milestones; erasure clears personal progress' result;rollback;
