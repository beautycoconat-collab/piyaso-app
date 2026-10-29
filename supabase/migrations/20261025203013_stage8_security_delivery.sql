begin;
create function kiyi_private.security_notice() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();sid uuid=nullif(auth.jwt()->>'session_id','')::uuid;begin
 if not kiyi_private.session_live(u) or not kiyi_private.account_active(u) or sid is null or not exists(select 1 from auth.sessions where id=sid and user_id=u) or exists(select 1 from auth.sessions where user_id=u and id<>sid) then raise exception 'Oturum kapatma sonucu doğrulanamadı.' using errcode='42501';end if;
 perform kiyi_private.social_rate(u,'security_notice',3);
 insert into public.kiyi_notifications(recipient,sender,kind,created,event_key) values(u,u,'security',(extract(epoch from clock_timestamp())*1000)::bigint,'other-sessions-closed:'||sid::text) on conflict do nothing;
 return '{"ok":true}'::jsonb;
end$$;
revoke all on function kiyi_private.security_notice() from public,anon,authenticated;
insert into kiyi_private.stage8_backup(name,definition) values('command_before_security_delivery',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure));
do $$declare d text;needle text=' if action=''delivery_settings'' then';begin
 d=pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure);
 if strpos(d,needle)=0 then raise exception 'Dispatcher shape changed';end if;
 d=replace(d,needle,' if action=''security_notice'' then return kiyi_private.security_notice();end if;'||chr(10)||needle);execute d;
end$$;
create index kiyi_delivery_pending_owner on kiyi_private.delivery_outbox(recipient) where state in ('waiting_configuration','queued','retry','leased');
-- Bound additional queue growth on the free plan. Existing in-app notices remain intact.
insert into kiyi_private.stage8_backup(name,definition) values('enqueue_before_capacity',pg_get_functiondef('kiyi_private.enqueue_delivery()'::regprocedure));
do $$declare d text;needle text=' foreach c in array array[''email'',''push''] loop';guard text=$guard$
 if not exists(select 1 from kiyi_private.delivery_preferences where owner=new.recipient and (email or push)) then return new;end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi-delivery-capacity',0));
 if (select count(*) from (select 1 from kiyi_private.delivery_outbox where state in ('waiting_configuration','queued','retry','leased') limit 5000)x)>=5000
 or (select count(*) from (select 1 from kiyi_private.delivery_outbox where recipient=new.recipient and state in ('waiting_configuration','queued','retry','leased') limit 200)x)>=200 then
 insert into kiyi_private.ops_events(kind,code) select 'delivery','queue_capacity' where not exists(select 1 from kiyi_private.ops_events where kind='delivery' and code='queue_capacity' and created_at>now()-interval '1 hour');
 return new;end if;
$guard$;begin
 d=pg_get_functiondef('kiyi_private.enqueue_delivery()'::regprocedure);
 if strpos(d,needle)=0 then raise exception 'Enqueue shape changed';end if;
 execute replace(d,needle,guard||needle);
end$$;
notify pgrst,'reload schema';
commit;
