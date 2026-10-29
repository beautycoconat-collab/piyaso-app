-- Roll back application code to version 114 only after this compatibility preflight passes.
-- No vehicles, purchases, inventory, ledger or artwork records are deleted.
begin;
do $$declare d text;begin
 if exists(select 1 from public.kiyi_vehicles where (is_primary and kind='motorcycle') or deleted_at is not null) then raise exception 'Rollback requires a compatible recovery release: new primary/deletion state exists. Do not discard it.';end if;
 select definition into strict d from kiyi_private.stage3_backup where key='command';execute d;
 select definition into strict d from kiyi_private.stage3_backup where key='person';execute d;
 select definition into strict d from kiyi_private.stage3_backup where key='viewport_map';execute d;
end$$;
update public.kiyi_vehicle_models m set ready=(b.definition::jsonb->>'ready')::boolean,parts=b.definition::jsonb->'parts' from kiyi_private.stage3_backup b where b.key='model:'||m.id;
-- New columns/products remain for safe forward recovery. No balance reversal is inferred.
commit;
