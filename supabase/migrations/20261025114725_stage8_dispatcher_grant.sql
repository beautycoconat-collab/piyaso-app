begin;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
commit;
