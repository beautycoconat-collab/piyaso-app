begin;
do $$declare d text;anchor text=$a$jsonb_build_object('vehicles','[]','count',0)$a$;begin
 d=pg_get_functiondef('kiyi_private.command_stage3(text,jsonb)'::regprocedure);
 if position(anchor in d)=0 then raise exception 'Private garage anchor missing';end if;
 insert into kiyi_private.stage5_backup values('garage_array_base',d);
 execute replace(d,anchor,$a$jsonb_build_object('vehicles','[]'::jsonb,'count',0)$a$);
end$$;
commit;
