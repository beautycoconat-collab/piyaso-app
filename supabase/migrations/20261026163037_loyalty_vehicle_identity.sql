begin;
create table kiyi_private.reward_vehicle_ids(owner uuid not null references auth.users on delete cascade,vehicle_id uuid not null,primary key(owner,vehicle_id));
alter table kiyi_private.reward_vehicle_ids enable row level security;
revoke all on kiyi_private.reward_vehicle_ids from public,anon,authenticated;
insert into kiyi_private.reward_vehicle_ids select owner,id from public.kiyi_vehicles where model_id is not null and plate_key is not null on conflict do nothing;
create table kiyi_private.reward_vehicle_plates(owner uuid not null references auth.users on delete cascade,plate_hash text not null,primary key(owner,plate_hash));
alter table kiyi_private.reward_vehicle_plates enable row level security;revoke all on kiyi_private.reward_vehicle_plates from public,anon,authenticated;
insert into kiyi_private.reward_vehicle_plates select owner,plate_hash from kiyi_private.reward_vehicles union select owner,md5(plate_key)from public.kiyi_vehicles where model_id is not null and plate_key is not null on conflict do nothing;
insert into kiyi_private.reward_backup(name,definition)values('reward_vehicle_event',pg_get_functiondef('kiyi_private.reward_vehicle_event()'::regprocedure)),('reward_erasure',pg_get_functiondef('kiyi_private.reward_erasure()'::regprocedure));
create or replace function kiyi_private.reward_vehicle_event() returns trigger language plpgsql security definer set search_path='' as $$
declare inserted int;new_plate int;begin
 if new.deleted_at is null and new.model_id is not null and new.plate_key is not null then
 insert into kiyi_private.reward_vehicle_plates values(new.owner,md5(new.plate_key))on conflict do nothing;get diagnostics new_plate=row_count;
 insert into kiyi_private.reward_vehicle_ids values(new.owner,new.id)on conflict do nothing;get diagnostics inserted=row_count;
 if inserted>0 and new_plate>0 then insert into kiyi_private.reward_vehicles values(new.owner,md5(new.plate_key),new.kind)on conflict do nothing;end if;
 end if;return new;
end$$;
do $$declare d text;needle text='delete from kiyi_private.reward_vehicles where owner=new.user_id;';begin
 d=pg_get_functiondef('kiyi_private.reward_erasure()'::regprocedure);
 if strpos(d,needle)=0 then raise exception 'Erasure shape changed';end if;
 execute replace(d,needle,needle||'delete from kiyi_private.reward_vehicle_ids where owner=new.user_id;delete from kiyi_private.reward_vehicle_plates where owner=new.user_id;');
end$$;
revoke all on function kiyi_private.reward_vehicle_event(),kiyi_private.reward_erasure() from public,anon,authenticated;
commit;
