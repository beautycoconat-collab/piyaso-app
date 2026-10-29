-- Only user-facing Turkish brand literals; technical identifiers stay unchanged.
do $$ declare f record; definition text; begin
 for f in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname in ('public','kiyi_private') and p.prokind='f' and p.prosrc like '%Kıyı%'
 loop
  definition=pg_get_functiondef(f.oid);
  execute replace(definition,'Kıyı','Piyaso');
 end loop;
end $$;
