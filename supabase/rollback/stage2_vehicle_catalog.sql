-- Non-destructive rollback. Refuses rollback while new model selections exist.
-- Retain migration while these models are in use; never silently reset users' selections.
begin;
lock table public.kiyi_appearance in access exclusive mode;
do $$declare d text;begin
 if exists(select 1 from public.kiyi_appearance where vehicle_model is not null and vehicle_model not in ('bmw-3','audi-a3','mercedes-c','vw-golf','renault-clio','fiat-egea','toyota-corolla')) then raise exception 'Rollback blocked: new models are in use; preserve selections and resolve before rollback';end if;
 select definition into strict d from kiyi_private.stage2_catalog_backup where key='command';execute d;
 alter table public.kiyi_appearance drop constraint kiyi_vehicle_model_catalog_fk;
 select definition into strict d from kiyi_private.stage2_catalog_backup where key='constraint';execute 'alter table public.kiyi_appearance add constraint kiyi_vehicle_model_allowlist '||d;
end $$;
drop table public.kiyi_vehicle_models;
drop table kiyi_private.stage2_catalog_backup;
commit;
