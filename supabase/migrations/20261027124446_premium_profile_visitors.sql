do $migration$
declare definition text;needle text := 'elsif action=''visits'' then return';replacement text := 'elsif action=''visits'' then if not is_premium then raise exception ''Profiline bakanları görmek için Premium gerekiyor.'' using errcode=''PT402'';end if; return';
begin
 definition := pg_get_functiondef('kiyi_private.command_pre_garage(text,jsonb)'::regprocedure);
 if strpos(definition,'errcode=''PT402''')>0 then return;end if;
 if strpos(definition,needle)=0 then raise exception 'Expected visits branch was not found; no change applied.';end if;
 execute replace(definition,needle,replacement);
end
$migration$;
