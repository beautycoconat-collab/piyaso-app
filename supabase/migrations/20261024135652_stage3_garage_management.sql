begin;
create table kiyi_private.stage3_backup(key text primary key,definition text not null);
alter table kiyi_private.stage3_backup enable row level security;
revoke all on kiyi_private.stage3_backup from public,anon,authenticated;
insert into kiyi_private.stage3_backup values('command',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure)),('person',pg_get_functiondef('kiyi_private.person(uuid)'::regprocedure)),('viewport_map',pg_get_functiondef('kiyi_private.viewport_map(uuid,jsonb)'::regprocedure));
alter table public.kiyi_vehicles add column deleted_at timestamptz,add column visibility text not null default 'private' check(visibility in ('private','public'));
-- Keep existing plate uniqueness; soft-deleted plates remain reserved until verified release.
create table public.kiyi_vehicle_part_products(model_id text references public.kiyi_vehicle_models,slot text not null,value jsonb not null,sku text not null,credits int not null check(credits>=0),primary key(model_id,slot,value));
alter table public.kiyi_vehicle_part_products enable row level security;
create policy part_products_read on public.kiyi_vehicle_part_products for select to authenticated using(true);
grant select on public.kiyi_vehicle_part_products to authenticated;
alter function kiyi_private.command(text,jsonb) rename to command_stage2;
revoke all on function kiyi_private.command_stage2(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();t uuid;v public.kiyi_vehicles;m public.kiyi_vehicle_models;r jsonb;a jsonb;e record;p public.kiyi_vehicle_part_products;cost int=0;rid uuid;ref text;version int;initial_color text;nextid uuid;
begin
 perform kiyi_private.command_stage2('bundle','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if payload?'vehicle_id' and not exists(select 1 from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null) then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 if action='directory' and payload?'plate' then
 r=kiyi_private.command_stage2('directory',payload);
 for e in select g.* from public.kiyi_vehicles g where g.plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g') and g.deleted_at is null and g.visibility='public' and g.owner<>u loop
 a=kiyi_private.command('garage_public',jsonb_build_object('target',e.owner));
 if exists(select 1 from jsonb_array_elements(a->'vehicles') z where z->>'id'=e.id::text) and not exists(select 1 from jsonb_array_elements(r->'profiles') z where z->>'id'=e.owner::text) then
 r=jsonb_set(r,'{profiles}',(r->'profiles')||jsonb_build_array(kiyi_private.person(e.owner)||jsonb_build_object('plate',e.plate,'vehicleKind',e.kind,'matchedVehicle',e.id)));
 end if;
 end loop;return r;
 elsif action in ('garage_list','garage_public') then
 t=case when action='garage_public' then (payload->>'target')::uuid else u end;
 if t is null or (t<>u and (not kiyi_private.account_active(t) or kiyi_private.blocked(u,t) or not exists(select 1 from public.kiyi_profiles where user_id=t and searchable and deleted_at is null) or (exists(select 1 from public.kiyi_privacy where user_id=t and ghost) and not kiyi_private.premium(u)) or (exists(select 1 from public.kiyi_positions pos join public.kiyi_regions reg on reg.id=pos.region where pos.user_id=t and reg.premium) and not kiyi_private.premium(u) and not exists(select 1 from public.kiyi_entitlements where user_id=t and featured)))) then return jsonb_build_object('vehicles','[]','count',0);end if;
 select coalesce(jsonb_agg(to_jsonb(q) order by q.created_at),'[]') into r from(select g.id,g.model_id,g.kind,g.plate,g.is_primary,g.visibility,g.created_at,c.appearance,c.version,cat.name,cat.ready from public.kiyi_vehicles g join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id left join public.kiyi_vehicle_models cat on cat.id=g.model_id where g.owner=t and g.deleted_at is null and (t=u or g.visibility='public') and (g.model_id is not null or nullif(g.plate,'') is not null))q;
 return jsonb_build_object('vehicles',r,'count',jsonb_array_length(r),'models',case when t=u then(select jsonb_agg(to_jsonb(cat) order by name) from public.kiyi_vehicle_models cat) else '[]'::jsonb end,'products',case when t=u then(select coalesce(jsonb_agg(to_jsonb(pp)),'[]') from public.kiyi_vehicle_part_products pp) else '[]'::jsonb end);
 elsif action='vehicle_create' then
 initial_color=coalesce(payload->>'paint','#ffffff');if initial_color !~ '^#[0-9a-f]{6}$' then raise exception 'Geçersiz renk.';end if;
 r=kiyi_private.command_stage2(action,payload);
 update public.kiyi_vehicle_customizations set appearance=appearance||jsonb_build_object('paint',initial_color,'factoryPaint',initial_color) where vehicle_id=(r->>'id')::uuid;
 if not exists(select 1 from public.kiyi_vehicles where owner=u and is_primary and deleted_at is null and nullif(plate,'') is not null) then
 perform kiyi_private.command('vehicle_primary',jsonb_build_object('vehicle_id',r->>'id'));
 end if;
 return r;
 elsif action in ('vehicle_update','vehicle_delete','vehicle_primary') then
 select * into v from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null for update;
 if not found then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 if action='vehicle_delete' then
 if v.is_primary and exists(select 1 from public.kiyi_verifications where user_id=u and status='approved') then raise exception 'Doğrulanmış plakan için değişiklik talebi gönder.';end if;
 update public.kiyi_vehicles set deleted_at=now(),is_primary=false where id=v.id;
 if v.is_primary then
 select id into nextid from public.kiyi_vehicles where owner=u and deleted_at is null and id<>v.id and nullif(plate,'') is not null order by created_at limit 1;
 if nextid is not null then perform kiyi_private.command('vehicle_primary',jsonb_build_object('vehicle_id',nextid));
 else update public.kiyi_profiles set profile=profile||'{"plate":"","car":""}'::jsonb where user_id=u;update public.kiyi_appearance set vehicle_model=null where user_id=u;end if;
 end if;
 return jsonb_build_object('ok',true);
 elsif action='vehicle_primary' then
 if exists(select 1 from public.kiyi_verifications where user_id=u and status='approved' and plate is distinct from v.plate) then raise exception 'Doğrulanmış plakan için değişiklik talebi gönder.';end if;
 update public.kiyi_vehicles set is_primary=false where owner=u;
 update public.kiyi_vehicles set is_primary=true where id=v.id;
 select appearance into a from public.kiyi_vehicle_customizations where vehicle_id=v.id;
 update public.kiyi_appearance set vehicle_model=v.model_id,paint=coalesce(a->>'paint','#ffffff'),plate_style=coalesce(a->>'plateStyle','classic'),plate_names=coalesce(a->'plateNames','{}') where user_id=u;
 update public.kiyi_profiles set profile=profile||jsonb_build_object('plate',v.plate,'car',(select name from public.kiyi_vehicle_models where id=v.model_id)) where user_id=u;
 return jsonb_build_object('ok',true);
 else
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if payload?'plate' then
 if length(trim(payload->>'plate')) not between 1 and 30 then raise exception 'Plakanı kontrol et.';end if;
 if v.is_primary then perform kiyi_private.command_stage2('profile',jsonb_build_object('profile',jsonb_build_object('plate',payload->>'plate')));
 else
 if exists(select 1 from public.kiyi_profiles where plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g')) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 update public.kiyi_vehicles set plate=payload->>'plate' where id=v.id;
 end if;end if;
 if payload?'visibility' then update public.kiyi_vehicles set visibility=payload->>'visibility' where id=v.id;end if;
 return jsonb_build_object('ok',true);
 end if;
 elsif action='motorcycle_customize' then
 select * into v from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null for update;
 select * into m from public.kiyi_vehicle_models where id=v.model_id and kind='motorcycle' and ready;
 if v.id is null or m.id is null then raise exception 'Motosiklet görseli ve katmanları henüz hazır değil.' using errcode='22023';end if;
 a=payload->'appearance';rid=(payload->>'request_id')::uuid;ref=v.id::text||':'||a::text;
 if rid is null or jsonb_typeof(a) is distinct from 'object' or octet_length(a::text)>4000 then raise exception 'Geçersiz işlem.';end if;
 if exists(select 1 from public.kiyi_ledger where owner=u and request_id=rid) then
 if not exists(select 1 from public.kiyi_ledger where owner=u and request_id=rid and reference=ref and kind='vehicle_parts') then raise exception 'İşlem kimliği daha önce kullanıldı.';end if;
 return jsonb_build_object('ok',true,'replayed',true);end if;
 select c.version into version from public.kiyi_vehicle_customizations c where c.vehicle_id=v.id;
 if version is distinct from (payload->>'version')::int then raise exception 'Araç güncellendi; yeniden yükle.' using errcode='40001';end if;
 select coalesce(c.appearance->>'factoryPaint',c.appearance->>'paint','#ffffff') into initial_color from public.kiyi_vehicle_customizations c where c.vehicle_id=v.id;
 for e in select * from jsonb_each(a) loop
 if e.key='paint' and e.value=to_jsonb(initial_color) then continue;end if;
 select * into p from public.kiyi_vehicle_part_products where model_id=m.id and slot=e.key and value=e.value;
 if not found then raise exception 'Modelle uyumsuz parça.' using errcode='22023';end if;
 if not exists(select 1 from public.kiyi_inventory where owner=u and sku=p.sku) then cost=cost+p.credits;end if;
 end loop;
 update public.kiyi_wallets set balance=balance-cost where user_id=u and balance>=cost;
 if not found then raise exception 'Yeterli kredi yok.';end if;
 for e in select * from jsonb_each(a) loop
 insert into public.kiyi_inventory(owner,sku) select u,sku from public.kiyi_vehicle_part_products where model_id=m.id and slot=e.key and value=e.value on conflict do nothing;
 end loop;
 insert into public.kiyi_ledger(owner,request_id,amount,kind,reference) values(u,rid,-cost,'vehicle_parts',ref);
 update public.kiyi_vehicle_customizations set appearance=appearance||a,version=version+1,updated_at=now() where vehicle_id=v.id;
 if v.is_primary and a?'paint' then update public.kiyi_appearance set paint=a->>'paint' where user_id=u;end if;
 return jsonb_build_object('ok',true,'charged',cost);
 end if;
 return kiyi_private.command_stage2(action,payload);
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;grant execute on function kiyi_private.command(text,jsonb) to authenticated;

-- Keep map eligibility, precision, ghost identities, sampling and regions unchanged.
do $patch$declare d text;anchor text;begin
 select pg_get_functiondef('kiyi_private.viewport_map(uuid,jsonb)'::regprocedure) into d;
 anchor:='where point(l.lng,l.lat)<@box(point(w,s),point(e,n))';
 if position(anchor in d)=0 then raise exception 'Map anchor missing';end if;
 d=replace(d,anchor,anchor||$s$ and (coalesce(p->>'vehicle_kind','all')='all' or coalesce((select kind from public.kiyi_vehicles where owner=l.user_id and is_primary and deleted_at is null),'car')=p->>'vehicle_kind')$s$);
 anchor:=$s$jsonb_build_object('pos',jsonb_build_array$s$;
 if position(anchor in d)=0 then raise exception 'Map kind anchor missing';end if;
 d=replace(d,anchor,$s$jsonb_build_object('vehicleKind',coalesce((select kind from public.kiyi_vehicles where owner=x.user_id and is_primary and deleted_at is null),'car'),'pos',jsonb_build_array$s$);execute d;
 select pg_get_functiondef('kiyi_private.person(uuid)'::regprocedure) into d;
 anchor:=$s$jsonb_build_object('id',p.user_id,$s$;
 if position(anchor in d)=0 then raise exception 'Person anchor missing';end if;
 d=replace(d,anchor,$s$jsonb_build_object('vehicleKind',coalesce((select kind from public.kiyi_vehicles where owner=p.user_id and is_primary and deleted_at is null),'car'),'vehicleCount',(select count(*) from public.kiyi_vehicles g where g.owner=p.user_id and g.deleted_at is null and (g.model_id is not null or nullif(g.plate,'') is not null) and (auth.uid()=p.user_id or (g.visibility='public' and (kiyi_private.premium(auth.uid()) or not exists(select 1 from public.kiyi_privacy q where q.user_id=p.user_id and q.ghost))))),'id',p.user_id,$s$);execute d;
end $patch$;
commit;
