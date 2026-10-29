-- Restore only behavior; do not restore deleted data. No DROP CASCADE.
begin;
drop function kiyi_private.command(text,jsonb);
alter function kiyi_private.command_stage7_final(text,jsonb) rename to command;
do $$begin execute (select definition from kiyi_private.stage8_backup where name='viewport_map');end$$;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
