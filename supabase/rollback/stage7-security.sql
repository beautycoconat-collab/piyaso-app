-- Restore function definitions only; do not restore erased personal data.
begin;
do $$declare f record;begin for f in select * from kiyi_private.stage7_function_backup order by name loop execute f.definition;end loop;end$$;
-- The patched Edge Function can continue calling the restored guard only after
-- restoring its preceding version. Coordinate that rollback before use.
notify pgrst,'reload schema';
commit;
