begin;
insert into kiyi_private.stage8_backup(name,definition) values('allowed_before_expiry',pg_get_functiondef('kiyi_private.delivery_allowed(kiyi_private.delivery_outbox)'::regprocedure));
do $$declare d text;needle text='declare p kiyi_private.delivery_preferences;begin';begin
 d=pg_get_functiondef('kiyi_private.delivery_allowed(kiyi_private.delivery_outbox)'::regprocedure);
 if strpos(d,needle)=0 then raise exception 'Delivery guard shape changed';end if;
 execute replace(d,needle,needle||chr(10)||' if j.expires_at<=now() then return false;end if;');
end$$;
commit;
