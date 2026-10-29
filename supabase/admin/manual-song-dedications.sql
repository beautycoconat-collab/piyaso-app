-- Preserve authorization, wallet, idempotency and notifications; replace only catalog validation.
do $migration$
declare definition text; old_line text; replacement text;
begin
 definition=pg_get_functiondef('kiyi_private.command_pre_garage(text,jsonb)'::regprocedure);
 select line into strict old_line from regexp_split_to_table(definition,E'\n') line
 where line like '%payload->''song''->>''url''%' and line like '%Geçerli bir şarkı seç.%';
 replacement=$validation$   if jsonb_typeof(payload->'song') is distinct from 'object'
    or payload->'song'->>'source' is distinct from 'manual'
    or jsonb_typeof(payload->'song'->'title') is distinct from 'string'
    or length(btrim(coalesce(payload->'song'->>'title',''))) not between 1 and 150
    or length(coalesce(payload->'song'->>'artist',''))>150
    or coalesce(payload->'song'->>'url','')<>''
    or coalesce(payload->'song'->>'artwork','')<>''
   then raise exception 'Şarkı adını yaz (en fazla 150 karakter).';end if;$validation$;
 execute replace(definition,old_line,replacement);
end;
$migration$;
