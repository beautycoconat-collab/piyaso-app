-- PostgREST 14 retries 40001 indefinitely. Business-version conflicts are HTTP 409.
begin;
do $$declare fn text;d text;begin
 foreach fn in array array['command','command_stage3','command_stage2'] loop
 select pg_get_functiondef(format('kiyi_private.%I(text,jsonb)',fn)::regprocedure) into d;
 if position('40001' in d)=0 then raise exception 'Expected conflict guard missing in %',fn;end if;
 insert into kiyi_private.stage4_backup(key,definition) values('http:'||fn,d);
 execute replace(d,'''40001''','''PT409''');
 end loop;
end$$;
commit;

