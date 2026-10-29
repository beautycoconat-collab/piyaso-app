begin;
do $$declare d text;anchor text='delete from public.kiyi_likes where post=postid and person=u';begin
 d=pg_get_functiondef('kiyi_private.command_pre_garage(text,jsonb)'::regprocedure);
 if position(anchor in d)=0 then raise exception 'Unlike query anchor missing';end if;
 insert into kiyi_private.stage5_backup values('unlike_base',d);
 execute replace(d,anchor,'delete from public.kiyi_likes l where l.post=postid and l.person=u');
end$$;
commit;
