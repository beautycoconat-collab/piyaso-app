begin;
create table kiyi_private.delivery_preferences(
 owner uuid primary key references auth.users on delete cascade,
 email boolean not null default false,push boolean not null default false,
 events jsonb not null default '{}' check(jsonb_typeof(events)='object' and octet_length(events::text)<500),updated_at timestamptz not null default now());
create table kiyi_private.delivery_outbox(
 id uuid primary key default gen_random_uuid(),recipient uuid not null references auth.users on delete cascade,
 channel text not null check(channel in ('email','push')),kind text not null,event_key text not null,
 notification_id uuid references public.kiyi_notifications on delete cascade,
 state text not null default 'waiting_configuration' check(state in ('waiting_configuration','queued','leased','retry','accepted','cancelled','failed')),
 attempts int not null default 0 check(attempts between 0 and 5),lease uuid,lease_until timestamptz,
 available_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '24 hours',
 created_at timestamptz not null default now(),accepted_at timestamptz,last_code text,
 unique(recipient,channel,event_key));
create index kiyi_delivery_claim on kiyi_private.delivery_outbox(channel,state,available_at,created_at);
alter table kiyi_private.delivery_preferences enable row level security;
alter table kiyi_private.delivery_outbox enable row level security;
revoke all on kiyi_private.delivery_preferences,kiyi_private.delivery_outbox from public,anon,authenticated;
insert into kiyi_private.ops_settings(key,value) values('delivery_email_enabled','false'),('delivery_push_enabled','false') on conflict do nothing;

create function kiyi_private.delivery_allowed(j kiyi_private.delivery_outbox) returns boolean language plpgsql stable security definer set search_path='' as $$
declare p kiyi_private.delivery_preferences;begin
 select * into p from kiyi_private.delivery_preferences where owner=j.recipient;
 if p.owner is null or (j.kind<>'account_deletion' and not kiyi_private.account_active(j.recipient)) or not(case when j.channel='email' then p.email else p.push end) or coalesce((p.events->>j.kind)::boolean,true)=false then return false;end if;
 if j.notification_id is not null and kiyi_private.notification_json(j.notification_id,j.recipient) is null then return false;end if;
 if j.channel='push' and not exists(select 1 from public.kiyi_devices where owner=j.recipient and enabled and nullif(push_token,'') is not null) then return false;end if;
 if j.channel='email' and not exists(select 1 from auth.users where id=j.recipient and email_confirmed_at is not null and nullif(email,'') is not null) then return false;end if;
 return true;
end$$;

create function kiyi_private.enqueue_delivery() returns trigger language plpgsql security definer set search_path='' as $$
declare k text=new.kind;c text;begin
 if k='gift' and exists(select 1 from public.kiyi_gifts where id=new.gift_id and product='song') then k='song';end if;
 if k not in ('follow','like','comment','tag','badge','gift','song','verification','security','admin','account_deletion') then return new;end if;
 -- No historical backfill and no default opt-in. Outbox and source insert commit together.
 foreach c in array array['email','push'] loop
 if exists(select 1 from kiyi_private.delivery_preferences p where p.owner=new.recipient and (case when c='email' then p.email else p.push end) and coalesce((p.events->>k)::boolean,true)) then
 insert into kiyi_private.delivery_outbox(recipient,channel,kind,event_key,notification_id) values(new.recipient,c,k,'notification:'||new.id::text,new.id) on conflict do nothing;
 end if;end loop;return new;
end$$;
create trigger stage8_delivery_note after insert on public.kiyi_notifications for each row execute function kiyi_private.enqueue_delivery();

create function kiyi_private.delivery_settings(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();k text;e jsonb;begin
 if not kiyi_private.session_live(u) or not kiyi_private.account_active(u) then raise exception 'Giriş yapmalısın.' using errcode='42501';end if;
 perform kiyi_private.social_rate(u,'delivery_settings',15);
 if exists(select 1 from jsonb_object_keys(payload) key where key not in ('email','push','events')) then raise exception 'Geçersiz tercih.' using errcode='22023';end if;
 foreach k in array array['email','push'] loop if payload?k and jsonb_typeof(payload->k)<>'boolean' then raise exception 'Geçersiz tercih.' using errcode='22023';end if;end loop;
 e=coalesce(payload->'events','{}');
 if jsonb_typeof(e)<>'object' or exists(select 1 from jsonb_each(e) x where x.key not in ('follow','like','comment','tag','badge','gift','song','verification','security','admin','account_deletion') or jsonb_typeof(x.value)<>'boolean') then raise exception 'Geçersiz olay tercihi.' using errcode='22023';end if;
 insert into kiyi_private.delivery_preferences(owner) values(u) on conflict do nothing;
 update kiyi_private.delivery_preferences p set email=coalesce((payload->>'email')::boolean,p.email),push=coalesce((payload->>'push')::boolean,p.push),events=p.events||e,updated_at=now() where owner=u;
 -- Revocation permanently cancels old pending jobs; re-enabling does not replay them.
 update kiyi_private.delivery_outbox j set state='cancelled',lease=null,lease_until=null,last_code='preference_revoked' where recipient=u and state in ('waiting_configuration','queued','retry','leased') and not kiyi_private.delivery_allowed(j);
 return jsonb_build_object('preferences',(select to_jsonb(p)-'owner' from kiyi_private.delivery_preferences p where owner=u),'email_available',coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='delivery_email_enabled'),false),'push_available',coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='delivery_push_enabled'),false));
end$$;

create function kiyi_private.delivery_worker(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare c text=payload->>'channel';j kiyi_private.delivery_outbox;r jsonb='[]';n int;begin
 if action='claim' then
 if c not in ('email','push') or c is null then raise exception 'Invalid channel';end if;
 if not coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='delivery_'||c||'_enabled'),false) then return jsonb_build_object('status','pending_configuration','jobs','[]'::jsonb);end if;
 for j in select * from kiyi_private.delivery_outbox where channel=c and state in ('waiting_configuration','queued','retry','leased') and (state<>'leased' or lease_until<now()) and available_at<=now() order by created_at,id limit 20 for update skip locked loop
 if j.expires_at<now() or j.attempts>=5 or not kiyi_private.delivery_allowed(j) then update kiyi_private.delivery_outbox set state='cancelled',lease=null,lease_until=null,last_code='expired_or_not_allowed' where id=j.id;continue;end if;
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
 'tokens',case when j.channel='push' then(select jsonb_agg(push_token) from public.kiyi_devices where owner=j.recipient and enabled and nullif(push_token,'') is not null)else null end);
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
create function kiyi_private.delivery_system_event() returns trigger language plpgsql security definer set search_path='' as $$
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
 end if;return new;
end$$;
revoke all on function kiyi_private.delivery_system_event() from public,anon,authenticated;
create trigger stage8_delivery_verification after update of status on public.kiyi_verifications for each row execute function kiyi_private.delivery_system_event();
create trigger stage8_delivery_case after update of status on kiyi_private.ops_cases for each row execute function kiyi_private.delivery_system_event();

revoke all on function kiyi_private.delivery_allowed(kiyi_private.delivery_outbox),kiyi_private.enqueue_delivery(),kiyi_private.delivery_settings(jsonb),kiyi_private.delivery_worker(text,jsonb) from public,anon,authenticated;
create function public.kiyi_delivery_worker(action text,payload jsonb default '{}') returns jsonb language sql security definer set search_path='' as $$select kiyi_private.delivery_worker(action,payload)$$;
revoke all on function public.kiyi_delivery_worker(text,jsonb) from public,anon,authenticated;
grant execute on function public.kiyi_delivery_worker(text,jsonb) to service_role;
-- Only the existing authenticated dispatcher exposes owner-scoped settings.
insert into kiyi_private.stage8_backup(name,definition) values('command_before_delivery',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure));
do $$declare d text;begin
 d=pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure);
 d=replace(d,' if action in (''directory'',''tag_search'') then',' if action=''delivery_settings'' then return kiyi_private.delivery_settings(payload);end if;'||chr(10)||' if action in (''directory'',''tag_search'') then');
 execute d;
end$$;
notify pgrst,'reload schema';
commit;
