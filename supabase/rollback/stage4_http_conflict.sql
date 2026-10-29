-- Diagnostic only: restores retry-loop risk. Normal UI rollback keeps this fix.
-- No user records are removed.
begin;
do $$declare r record;begin
 for r in select definition from kiyi_private.stage4_backup where key like 'http:%' loop execute r.definition;end loop;
end$$;
commit;
