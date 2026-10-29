-- Additive appearance choice, through the existing authenticated/locked domain command.
-- Does not change wallets, paid inventory, visibility, media policies or admin access.
begin;
alter table public.kiyi_appearance add column if not exists vehicle_model text;
do $constraint$
begin
 if not exists(select 1 from pg_constraint where conrelid='public.kiyi_appearance'::regclass and conname='kiyi_vehicle_model_allowlist') then
  alter table public.kiyi_appearance add constraint kiyi_vehicle_model_allowlist check(vehicle_model in ('bmw-3','audi-a3','mercedes-c','vw-golf','renault-clio','fiat-egea','toyota-corolla'));
 end if;
end $constraint$;
do $patch$
declare definition text;anchor text;replacement text;
begin
 select pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure) into definition;
 if position('action=''vehicle_model''' in definition)=0 then
  anchor:=' if action=''profile_photos'' then';
  replacement:=$branch$ if action='vehicle_model' then
  prod=payload->>'model';
  if prod is null or not (prod=any(array['bmw-3','audi-a3','mercedes-c','vw-golf','renault-clio','fiat-egea','toyota-corolla'])) then raise exception 'Geçersiz araç modeli.' using errcode='22023';end if;
  if t is not null and t<>u then raise exception 'Yalnızca kendi aracını düzenleyebilirsin.' using errcode='42501';end if;
  update public.kiyi_appearance set vehicle_model=prod where user_id=u;
  update public.kiyi_profiles set profile=profile||jsonb_build_object('car',case prod when 'bmw-3' then 'BMW 3 Serisi' when 'audi-a3' then 'Audi A3' when 'mercedes-c' then 'Mercedes C Serisi' when 'vw-golf' then 'Volkswagen Golf' when 'renault-clio' then 'Renault Clio' when 'fiat-egea' then 'Fiat Egea' when 'toyota-corolla' then 'Toyota Corolla' end) where user_id=u;
  return jsonb_build_object('ok',true,'vehicleModel',prod);
 elsif action='profile_photos' then$branch$;
  if position(anchor in definition)=0 then raise exception 'Vehicle migration: command anchor missing; inspect current domain.';end if;
  execute replace(definition,anchor,replacement);
 end if;
 select pg_get_functiondef('kiyi_private.person(uuid)'::regprocedure) into definition;
 if position('''vehicleModel''' in definition)=0 then
  anchor:='''paint'',coalesce(a.paint,''#ffffff''),';
  if position(anchor in definition)=0 then raise exception 'Vehicle migration: person anchor missing; inspect current domain.';end if;
  execute replace(definition,anchor,anchor||'''vehicleModel'',a.vehicle_model,');
 end if;
end $patch$;
commit;
