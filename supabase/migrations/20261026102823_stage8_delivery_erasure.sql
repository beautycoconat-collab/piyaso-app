begin;
alter table public.kiyi_devices add column session_id uuid references auth.sessions(id) on delete cascade;
insert into kiyi_private.stage8_backup(name,definition) values('health_before_delivery_retention',pg_get_functiondef('kiyi_private.health_maintenance()'::regprocedure));
create index kiyi_delivery_expiry on kiyi_private.delivery_outbox(expires_at);
create or replace function kiyi_private.delivery_allowed(j kiyi_private.delivery_outbox) returns boolean language plpgsql stable security definer set search_path='' as $$
declare p kiyi_private.delivery_preferences;begin
 if j.kind='account_deletion' then return j.channel='email' and j.notification_id is null and exists(select 1 from kiyi_private.ops_cases where owner=j.recipient and kind='privacy' and subject='delete_account' and status='completed' and 'case-completed:'||id::text=j.event_key) and exists(select 1 from auth.users where id=j.recipient and email_confirmed_at is not null and nullif(email,'') is not null);end if;
 select * into p from kiyi_private.delivery_preferences where owner=j.recipient;
 if p.owner is null or (j.kind<>'account_deletion' and not kiyi_private.account_active(j.recipient)) or not(case when j.channel='email' then p.email else p.push end) or coalesce((p.events->>j.kind)::boolean,true)=false then return false;end if;
 if j.notification_id is not null and kiyi_private.notification_json(j.notification_id,j.recipient) is null then return false;end if;
 if j.channel='push' and not exists(select 1 from public.kiyi_devices d join auth.sessions ss on ss.id=d.session_id and ss.user_id=d.owner where d.owner=j.recipient and d.enabled and nullif(d.push_token,'') is not null and (ss.not_after is null or ss.not_after>now())) then return false;end if;
 if j.channel='email' and not exists(select 1 from auth.users where id=j.recipient and email_confirmed_at is not null and nullif(email,'') is not null) then return false;end if;
 return true;
end$$;
create or replace function kiyi_private.delivery_system_event() returns trigger language plpgsql security definer set search_path='' as $$
declare c text;begin
 if tg_table_name='kiyi_verifications' then
 if new.status is distinct from old.status and new.status in ('approved','rejected') then
 insert into public.kiyi_notifications(recipient,sender,kind,created,event_key) values(new.user_id,new.user_id,'verification',(extract(epoch from clock_timestamp())*1000)::bigint,'verification:'||new.user_id::text||':'||new.status||':'||txid_current()::text) on conflict do nothing;
 end if;
 elsif new.kind='privacy' and new.subject='delete_account' and new.status='completed' and old.status is distinct from new.status then
 -- Completion notices must survive the removal of in-app profile/notifications.
 foreach c in array array['email'] loop
 if exists(select 1 from kiyi_private.delivery_preferences where owner=new.owner and email and coalesce((events->>'account_deletion')::boolean,true)) then
 insert into kiyi_private.delivery_outbox(recipient,channel,kind,event_key) values(new.owner,c,'account_deletion','case-completed:'||new.id::text) on conflict do nothing;
 end if;end loop;
 update kiyi_private.delivery_outbox set state='cancelled',lease=null,lease_until=null,last_code='account_erased' where recipient=new.owner and kind<>'account_deletion' and state in ('waiting_configuration','queued','retry','leased');
 delete from kiyi_private.delivery_preferences where owner=new.owner;
 end if;return new;
end$$;create or replace function kiyi_private.delivery_worker(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare c text=payload->>'channel';j kiyi_private.delivery_outbox;r jsonb='[]';n int;begin
 if action='claim' then
 if c not in ('email','push') or c is null then raise exception 'Invalid channel';end if;
 if not coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='delivery_'||c||'_enabled'),false) then return jsonb_build_object('status','pending_configuration','jobs','[]'::jsonb);end if;
 for j in select * from kiyi_private.delivery_outbox where channel=c and state in ('waiting_configuration','queued','retry','leased') and (state<>'leased' or lease_until<now()) and available_at<=now() order by created_at,id limit 20 for update skip locked loop
 if j.attempts>=5 then update kiyi_private.delivery_outbox set state='failed',lease=null,lease_until=null,last_code='attempts_exhausted' where id=j.id;continue;end if;
 if j.expires_at<now() or not kiyi_private.delivery_allowed(j) then update kiyi_private.delivery_outbox set state='cancelled',lease=null,lease_until=null,last_code='expired_or_not_allowed' where id=j.id;continue;end if;
 update kiyi_private.delivery_outbox set state='leased',lease=gen_random_uuid(),lease_until=now()+interval '2 minutes',attempts=attempts+1 where id=j.id returning * into j;
 r=r||jsonb_build_array(jsonb_build_object('id',j.id,'lease',j.lease,'kind',j.kind));end loop;
 return jsonb_build_object('status','claimed','jobs',r);
 elsif action in ('resolve','ack') then
 select * into j from kiyi_private.delivery_outbox where id=(payload->>'id')::uuid and lease=(payload->>'lease')::uuid and lease_until>now() and state='leased' for update;
 if not found then raise exception 'Invalid or expired delivery lease' using errcode='42501';end if;
 if not coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='delivery_'||j.channel||'_enabled'),false) or not kiyi_private.delivery_allowed(j) then
 update kiyi_private.delivery_outbox set state='cancelled',lease=null,lease_until=null,last_code='permission_revoked' where id=j.id;return '{"status":"cancelled"}'::jsonb;end if;
 if action='resolve' then
 return jsonb_build_object('status','ready','id',j.id,'kind',j.kind,'channel',j.channel,'idempotency_key',j.id,
 'email',case when j.channel='email' then(select email from auth.users where id=j.recipient)else null end,
 'tokens',case when j.channel='push' then(select jsonb_agg(d.push_token) from public.kiyi_devices d join auth.sessions ss on ss.id=d.session_id and ss.user_id=d.owner where d.owner=j.recipient and d.enabled and nullif(d.push_token,'') is not null and (ss.not_after is null or ss.not_after>now()))else null end);
 end if;
 if payload->>'outcome'='accepted' then
 update kiyi_private.delivery_outbox set state='accepted',accepted_at=now(),lease=null,lease_until=null,last_code='provider_accepted' where id=j.id;
 elsif payload->>'outcome'='retry' then
 update kiyi_private.delivery_outbox set state=case when attempts>=5 then 'failed' else 'retry' end,available_at=now()+interval '1 minute'*least(60,power(2,j.attempts)::int),lease=null,lease_until=null,last_code='provider_retry' where id=j.id;
 elsif payload->>'outcome'='rejected' then update kiyi_private.delivery_outbox set state='failed',lease=null,lease_until=null,last_code='provider_rejected' where id=j.id;
 else raise exception 'Invalid outcome';end if;
 return '{"ok":true}'::jsonb;
 end if;raise exception 'Invalid worker action';
end$$;
create function kiyi_private.delivery_maintenance() returns void language plpgsql security definer set search_path='' as $$
begin
 update kiyi_private.delivery_outbox set state='cancelled',lease=null,lease_until=null,last_code='expired' where expires_at<now() and state in ('waiting_configuration','queued','retry','leased');
 -- Ephemeral delivery metadata only; preserve inbox, profiles, vehicles and financial records.
 delete from kiyi_private.delivery_outbox where expires_at<now()-interval '30 days';
end$$;
revoke all on function kiyi_private.delivery_maintenance() from public,anon,authenticated;
do $$declare d text;needle text='declare n bigint;removed bigint;begin';begin
 d=pg_get_functiondef('kiyi_private.health_maintenance()'::regprocedure);
 if strpos(d,needle)=0 then raise exception 'Health function shape changed';end if;
 execute replace(d,needle,needle||chr(10)||' perform kiyi_private.delivery_maintenance();');
end$$;
notify pgrst,'reload schema';
commit;
