begin;
create table kiyi_private.stage2_garage_backup as select 'command'::text as key,pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure) as definition;
alter table kiyi_private.stage2_garage_backup enable row level security;
revoke all on kiyi_private.stage2_garage_backup from public,anon,authenticated;
create table public.kiyi_vehicles(id uuid primary key default gen_random_uuid(),owner uuid not null references auth.users on delete cascade,model_id text references public.kiyi_vehicle_models,kind text not null check(kind in ('car','motorcycle')),plate text,plate_key text generated always as(nullif(regexp_replace(upper(plate),'[[:space:]]','','g'),'')) stored,is_primary boolean not null default false,created_at timestamptz not null default now());
create unique index kiyi_vehicles_plate on public.kiyi_vehicles(plate_key) where plate_key is not null;
create unique index kiyi_vehicles_primary on public.kiyi_vehicles(owner) where is_primary;
create index kiyi_vehicles_owner on public.kiyi_vehicles(owner);
create table public.kiyi_vehicle_customizations(vehicle_id uuid primary key references public.kiyi_vehicles on delete cascade,appearance jsonb not null default '{}',version int not null default 1,updated_at timestamptz not null default now(),check(jsonb_typeof(appearance)='object' and octet_length(appearance::text)<10000));
alter table public.kiyi_vehicles enable row level security;
alter table public.kiyi_vehicle_customizations enable row level security;
revoke all on public.kiyi_vehicles,public.kiyi_vehicle_customizations from public,anon,authenticated;
insert into public.kiyi_vehicles(owner,model_id,kind,plate,is_primary) select p.user_id,a.vehicle_model,'car',p.profile->>'plate',true from public.kiyi_profiles p left join public.kiyi_appearance a using(user_id) where p.deleted_at is null;
insert into public.kiyi_vehicle_customizations(vehicle_id,appearance) select v.id,jsonb_build_object('paint',coalesce(a.paint,'#ffffff'),'plateStyle',coalesce(a.plate_style,'classic'),'plateNames',coalesce(a.plate_names,'{}'),'wrap',null,'rim',null,'accessories','{}'::jsonb) from public.kiyi_vehicles v left join public.kiyi_appearance a on a.user_id=v.owner;
alter function kiyi_private.command(text,jsonb) rename to command_pre_garage;
revoke all on function kiyi_private.command_pre_garage(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();v public.kiyi_vehicles;m public.kiyi_vehicle_models;a jsonb;out jsonb;saved public.kiyi_appearance;vid uuid;
begin
 -- Existing dispatcher bootstraps accounts and enforces suspension/maintenance/deletion.
 perform kiyi_private.command_pre_garage('bundle','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if not exists(select 1 from public.kiyi_vehicles where owner=u) then
 insert into public.kiyi_vehicles(owner,kind,plate,is_primary,model_id) select u,'car',p.profile->>'plate',true,a.vehicle_model from public.kiyi_profiles p join public.kiyi_appearance a using(user_id) where p.user_id=u returning id into vid;
 insert into public.kiyi_vehicle_customizations(vehicle_id,appearance) select vid,jsonb_build_object('paint',paint,'plateStyle',plate_style,'plateNames',plate_names) from public.kiyi_appearance where user_id=u;
 end if;
 if action='garage_list' then return jsonb_build_object('vehicles',coalesce((select jsonb_agg(to_jsonb(t) order by t.created_at) from(select g.*,c.appearance,c.version,cat.ready,cat.name from public.kiyi_vehicles g join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id left join public.kiyi_vehicle_models cat on cat.id=g.model_id where g.owner=u)t),'[]'),'models',(select jsonb_agg(to_jsonb(cat) order by name) from public.kiyi_vehicle_models cat));
 elsif action='vehicle_create' then
 select * into m from public.kiyi_vehicle_models where id=payload->>'model';if not found then raise exception 'Geçersiz model.' using errcode='22023';end if;
 if length(trim(coalesce(payload->>'plate',''))) not between 1 and 30 then raise exception 'Plakanı kontrol et.';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if exists(select 1 from public.kiyi_profiles where plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g')) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 insert into public.kiyi_vehicles(owner,kind,model_id,plate) values(u,m.kind,m.id,payload->>'plate') returning * into v;
 insert into public.kiyi_vehicle_customizations(vehicle_id) values(v.id);return to_jsonb(v);
 elsif action in ('vehicle_customize','vehicle_model','appearance') and (action<>'appearance' or payload->>'kind'<>'frame') then
 select * into v from public.kiyi_vehicles where owner=u and (case when payload?'vehicle_id' then id=(payload->>'vehicle_id')::uuid else is_primary end) for update;
 if not found or (payload?'target' and (payload->>'target')::uuid<>u) then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 select * into m from public.kiyi_vehicle_models where id=coalesce(payload->>'model',v.model_id);
 if not (action='appearance' and v.kind='car' and v.model_id is null) and (m.id is null or not m.ready or m.kind<>v.kind) then raise exception 'Model katmanları henüz hazır değil.' using errcode='22023';end if;
 if action='vehicle_model' then
 update public.kiyi_vehicles set model_id=m.id where id=v.id;
 if v.is_primary then perform kiyi_private.command_pre_garage(action,payload);end if;
 return jsonb_build_object('ok',true,'vehicleModel',m.id,'vehicle_id',v.id);
 elsif action='appearance' then
 select * into saved from public.kiyi_appearance where user_id=u;
 select appearance into a from public.kiyi_vehicle_customizations where vehicle_id=v.id;
 update public.kiyi_appearance set paint=coalesce(a->>'paint','#ffffff'),plate_style=coalesce(a->>'plateStyle','classic'),plate_names=coalesce(a->'plateNames','{}') where user_id=u;
 out=kiyi_private.command_pre_garage(action,payload);
 update public.kiyi_vehicle_customizations c set appearance=c.appearance||jsonb_build_object('paint',s.paint,'plateStyle',s.plate_style,'plateNames',s.plate_names),version=version+1,updated_at=now() from public.kiyi_appearance s where c.vehicle_id=v.id and s.user_id=u;
 if not v.is_primary then update public.kiyi_appearance set paint=saved.paint,plate_style=saved.plate_style,plate_names=saved.plate_names where user_id=u;end if;
 return jsonb_build_object('ok',true,'vehicle_id',v.id);
 else
 a=payload->'appearance';
 if jsonb_typeof(a) is distinct from 'object' or exists(select 1 from jsonb_object_keys(a) k where k not in ('wrap','rim','accessories')) or octet_length(a::text)>4000 then raise exception 'Geçersiz özelleştirme.';end if;
 -- Choices must exist in the server-maintained compatibility catalog, never arbitrary client JSON.
 if exists(select 1 from jsonb_each(a) e where e.key<>'accessories' and not exists(select 1 from public.kiyi_vehicle_parts p where p.model_id=m.id and p.slot=e.key and p.value=e.value)) or (a?'accessories' and jsonb_typeof(a->'accessories') is distinct from 'object') then raise exception 'Bu parça modelle uyumlu değil.';end if;
 if a?'accessories' then
 if exists(select 1 from jsonb_each(a->'accessories') e where (e.key='text' and (jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>12)) or (e.key<>'text' and not exists(select 1 from public.kiyi_vehicle_parts p where p.model_id=m.id and p.slot=e.key and p.value=e.value))) then raise exception 'Geçersiz aksesuar.';end if;
 end if;
 if (payload->>'version')::int is distinct from (select version from public.kiyi_vehicle_customizations where vehicle_id=v.id) then raise exception 'Araç güncellendi; yeniden yükle.' using errcode='40001';end if;
 update public.kiyi_vehicle_customizations set appearance=appearance||a,version=version+1,updated_at=now() where vehicle_id=v.id;return jsonb_build_object('ok',true);
 end if;
 end if;
 if action='profile' then
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if payload->'profile'?'plate' and exists(select 1 from public.kiyi_vehicles where plate_key=regexp_replace(upper(payload->'profile'->>'plate'),'[[:space:]]','','g') and not(owner=u and is_primary)) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 end if;
 out=kiyi_private.command_pre_garage(action,payload);
 if action='profile' then update public.kiyi_vehicles g set plate=p.profile->>'plate' from public.kiyi_profiles p where g.owner=u and g.is_primary and p.user_id=u;end if;
 return out;
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;grant execute on function kiyi_private.command(text,jsonb) to authenticated;
create table public.kiyi_vehicle_parts(model_id text references public.kiyi_vehicle_models,slot text not null,value jsonb not null,primary key(model_id,slot,value));
alter table public.kiyi_vehicle_parts enable row level security;
create policy vehicle_parts_catalog on public.kiyi_vehicle_parts for select to authenticated using(true);
grant select on public.kiyi_vehicle_parts to authenticated;

insert into public.kiyi_vehicle_parts select id,'wrap','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"milk-wave"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"pink-star"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"spider-web"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"pink-kitten"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"pink-leopard"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"gold-leopard"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"retro-flower"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"race-95"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'wrap','"halloween"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"sport-red"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"sport-yellow"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"sport-five"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"split-ten"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"mesh-silver"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"turbine"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"stealth"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"mesh-gold"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"track-six"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"aero-disc"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"y-forged"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"deep-dish"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"bronze-track"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'rim','"rose-mesh"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'headlights','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'headlights','"head-ice"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'headlights','"head-cyan"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'headlights','"head-amber"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'headlights','"head-violet"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'underglow','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'underglow','"under-cyan"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'underglow','"under-violet"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'underglow','"under-red"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'underglow','"under-gold"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'window','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'window','"led-violet"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'window','"led-cyan"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'window','"heart-pink"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'window','"neon-text"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'roof','null'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'roof','"roof-bow"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'roof','"roof-stars"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
insert into public.kiyi_vehicle_parts select id,'roof','"roof-heart"'::jsonb from public.kiyi_vehicle_models where kind='car' and ready;
commit;
