-- M1 additive admin boundary. Existing application tables/functions are unchanged.
create table kiyi_private.admin_memberships (
 user_id uuid primary key references auth.users(id),
 role text not null check(role in ('super_admin','admin','moderator','finance','support')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id),
 version integer not null default 1
);
create table kiyi_private.admin_permissions (
 role text not null, permission text not null, primary key(role,permission)
);
insert into kiyi_private.admin_permissions values
 ('super_admin','dashboard.read'),('super_admin','users.read'),('super_admin','audit.read'),('super_admin','staff.read'),('super_admin','staff.manage'),
 ('admin','dashboard.read'),('admin','users.read'),('admin','audit.read'),
 ('moderator','dashboard.read'),('moderator','users.read'),
 ('finance','dashboard.read'),('support','users.read');
create table kiyi_private.admin_audit (
 id bigint generated always as identity primary key,
 actor uuid references auth.users(id), action text not null,
 entity_id text, reason text, details jsonb not null default '{}',
 request_id uuid, session_id uuid,
 created_at timestamptz not null default now()
);
create index admin_audit_created on kiyi_private.admin_audit(created_at desc,id desc);
create index admin_audit_actor on kiyi_private.admin_audit(actor,created_at desc);
create table kiyi_private.admin_leases (
 session_id uuid primary key, user_id uuid not null references auth.users(id),
 started_at timestamptz not null default now(), last_seen timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '8 hours', revoked_at timestamptz
);
create index admin_leases_owner on kiyi_private.admin_leases(user_id);
create table kiyi_private.admin_requests (
 actor uuid not null references auth.users(id), request_id uuid not null,
 action text not null, payload jsonb not null, result jsonb not null,
 primary key(actor,request_id)
);
alter table kiyi_private.admin_memberships enable row level security;
alter table kiyi_private.admin_permissions enable row level security;
alter table kiyi_private.admin_audit enable row level security;
alter table kiyi_private.admin_leases enable row level security;
alter table kiyi_private.admin_requests enable row level security;
revoke all on kiyi_private.admin_memberships,kiyi_private.admin_permissions,kiyi_private.admin_audit,kiyi_private.admin_leases,kiyi_private.admin_requests from public,anon,authenticated;
revoke all on sequence kiyi_private.admin_audit_id_seq from public,anon,authenticated;

-- AAL1 probe only reveals the caller's own membership, never app/staff data.
create function kiyi_private.admin_probe() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); r text; sid uuid;
begin
 if u is null or coalesce(auth.jwt()->>'is_anonymous','false')='true' then raise exception 'ADMIN_DENIED' using errcode='42501'; end if;
 sid=(auth.jwt()->>'session_id')::uuid;
 if sid is null or not exists(select 1 from auth.sessions where id=sid and user_id=u) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
 select role into r from kiyi_private.admin_memberships where user_id=u and active;
 if r is null then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
 return jsonb_build_object('role',r,'user_id',u,'mfa_required',true);
end $$;

create function kiyi_private.admin_recent_mfa() returns boolean language sql stable security invoker set search_path='' as $$
 select coalesce(auth.jwt()->>'aal'='aal2' and exists(
 select 1 from jsonb_array_elements(coalesce(auth.jwt()->'amr','[]')) a
 where a->>'method'='totp' and (a->>'timestamp')::numeric between extract(epoch from now()-interval '5 minutes') and extract(epoch from now()+interval '30 seconds')),false)
$$;

create function kiyi_private.admin_authorize(permission text,open_lease boolean default false) returns text language plpgsql security definer set search_path='' as $$
declare me jsonb; u uuid=auth.uid(); sid uuid=(auth.jwt()->>'session_id')::uuid; r text;
begin
 me=kiyi_private.admin_probe();r=me->>'role';
 if auth.jwt()->>'aal' is distinct from 'aal2' then raise exception 'ADMIN_MFA_REQUIRED' using errcode='42501';end if;
 if not exists(select 1 from kiyi_private.admin_permissions p where p.role=r and p.permission=admin_authorize.permission) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
 if open_lease and not exists(select 1 from kiyi_private.admin_leases where session_id=sid and revoked_at is null and last_seen>now()-interval '15 minutes' and expires_at>now()) then
  if not kiyi_private.admin_recent_mfa() then raise exception 'ADMIN_REAUTH_REQUIRED' using errcode='42501';end if;
  -- A revoked session may never be reopened with its old JWT.
  if exists(select 1 from kiyi_private.admin_leases where session_id=sid and revoked_at is not null) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  insert into kiyi_private.admin_leases(session_id,user_id) values(sid,u)
  on conflict(session_id) do update set started_at=now(),last_seen=now(),expires_at=now()+interval '8 hours';
 end if;
 update kiyi_private.admin_leases set last_seen=now() where session_id=sid and user_id=u and revoked_at is null and last_seen>now()-interval '15 minutes' and expires_at>now();
 if not found then raise exception 'ADMIN_REAUTH_REQUIRED' using errcode='42501';end if;
 return r;
end $$;

-- Deliberately no finance mutation, sanctions, arbitrary SQL or owner elevation in M1.
create function kiyi_private.admin_command(action text,payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); sid uuid=(auth.jwt()->>'session_id')::uuid;r text;result jsonb; q text;lim int; cursor_id uuid;t uuid;why text;rid uuid;oldrow jsonb;v int;
begin
 if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>8000 then raise exception 'ADMIN_INVALID_INPUT';end if;
 if action='probe' then return kiyi_private.admin_probe();end if;
 if action='session' then
  -- staff with any permission may open a lease; use their first allowed permission.
  perform kiyi_private.admin_probe();select permission into q from kiyi_private.admin_permissions where role=(select role from kiyi_private.admin_memberships where user_id=u) order by permission limit 1;
  r=kiyi_private.admin_authorize(q,true);
  select jsonb_build_object('user_id',u,'role',r,'permissions',jsonb_agg(permission),'session_expires_at',(select expires_at from kiyi_private.admin_leases where session_id=sid)) into result from kiyi_private.admin_permissions where role=r;
 elsif action='summary' then
  r=kiyi_private.admin_authorize('dashboard.read');
  result=jsonb_build_object('profiles',(select count(*) from public.kiyi_profiles),'new_today',(select count(*) from public.kiyi_profiles where created_at>=date_trunc('day',now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul'),'regions',(select count(*) from public.kiyi_regions),'premium',(select count(*) from public.kiyi_entitlements where premium_until>now() and not suspended),'reports',case when r in ('super_admin','admin','moderator') then (select count(*) from public.kiyi_reports where status='pending') else null end,'payments_connected',false,'online_available',false,'as_of',now());
 elsif action='users' then
  r=kiyi_private.admin_authorize('users.read');
  q=trim(coalesce(payload->>'query',''));if length(q)>60 then raise exception 'ADMIN_INVALID_INPUT';end if;
  cursor_id=nullif(payload->>'cursor','')::uuid;lim=least(50,greatest(1,coalesce((payload->>'limit')::int,25)));
  select coalesce(jsonb_agg(to_jsonb(z)),'[]') into result from(
   select p.user_id,p.username,p.created_at,p.searchable,coalesce(e.verified,false) verified,coalesce(e.suspended,false) suspended,
    case when r in ('super_admin','admin','moderator') then left(p.profile->>'plate',2)||' •••' else null end plate_masked
   from public.kiyi_profiles p left join public.kiyi_entitlements e on e.user_id=p.user_id
   where (cursor_id is null or p.user_id>cursor_id) and (q='' or p.username ilike replace(replace(replace(q,'\','\\'),'%','\%'),'_','\_')||'%' or regexp_replace(upper(p.profile->>'plate'),'\s','','g')=regexp_replace(upper(q),'\s','','g'))
   order by p.user_id limit lim
  )z;
  result=jsonb_build_object('items',result,'next_cursor',case when jsonb_array_length(result)=lim then result->(lim-1)->>'user_id' else null end);
 elsif action='audit' then
  r=kiyi_private.admin_authorize('audit.read');
  select coalesce(jsonb_agg(to_jsonb(z)),'[]') into result from(select id,actor,action,entity_id,reason,details,created_at from kiyi_private.admin_audit where (nullif(payload->>'cursor','') is null or id<(payload->>'cursor')::bigint) order by id desc limit 50)z;
  result=jsonb_build_object('items',result,'next_cursor',case when jsonb_array_length(result)=50 then result->49->>'id' else null end);
 elsif action='staff' then
  r=kiyi_private.admin_authorize('staff.read');
  select jsonb_build_object('items',coalesce(jsonb_agg(to_jsonb(z)),'[]')) into result from(select user_id,role,active,created_at,updated_at,version from kiyi_private.admin_memberships order by created_at limit 100)z;
 elsif action in ('staff_grant','staff_revoke') then
  r=kiyi_private.admin_authorize('staff.manage');
  if not kiyi_private.admin_recent_mfa() then raise exception 'ADMIN_REAUTH_REQUIRED' using errcode='42501';end if;
  rid=(payload->>'request_id')::uuid;t=(payload->>'user_id')::uuid;why=trim(coalesce(payload->>'reason',''));v=(payload->>'expected_version')::int;
  if rid is null or t is null or t=u or length(why) not between 10 and 300 or v is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  -- Serialize staff changes including request replay, revocation, and optimistic versions.
  perform pg_advisory_xact_lock(hashtextextended('kiyi-admin-staff',0));
  select ar.result into result from kiyi_private.admin_requests ar where ar.actor=u and ar.request_id=rid;
  if found then
   if not exists(select 1 from kiyi_private.admin_requests ar where ar.actor=u and ar.request_id=rid and ar.action=admin_command.action and ar.payload=admin_command.payload) then raise exception 'ADMIN_REQUEST_CONFLICT';end if;
   return result;
  end if;
  select to_jsonb(m) into oldrow from kiyi_private.admin_memberships m where user_id=t for update;
  if oldrow->>'role'='super_admin' then raise exception 'ADMIN_OWNER_PROTECTED' using errcode='42501';end if;
  if coalesce((oldrow->>'version')::int,0)<>v then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  if action='staff_grant' then
   if payload->>'role' is null or payload->>'role' not in ('admin','moderator','finance','support') or not exists(select 1 from public.kiyi_profiles where user_id=t) then raise exception 'ADMIN_INVALID_INPUT';end if;
   insert into kiyi_private.admin_memberships(user_id,role,updated_by) values(t,payload->>'role',u)
   on conflict(user_id) do update set role=excluded.role,active=true,updated_at=now(),updated_by=u,version=kiyi_private.admin_memberships.version+1;
  else
   if oldrow is null then raise exception 'ADMIN_INVALID_INPUT';end if;
   update kiyi_private.admin_memberships set active=false,updated_at=now(),updated_by=u,version=version+1 where user_id=t;
  end if;
  update kiyi_private.admin_leases set revoked_at=now() where user_id=t and revoked_at is null;
  result=jsonb_build_object('ok',true);
  insert into kiyi_private.admin_requests values(u,rid,action,payload,result);
  insert into kiyi_private.admin_audit(actor,action,entity_id,reason,details,request_id,session_id) values(u,action,t::text,why,jsonb_build_object('before_role',oldrow->>'role','after_role',case when action='staff_grant' then payload->>'role' else oldrow->>'role' end,'active',action='staff_grant'),rid,sid);
  return result;
 elsif action='logout' then
  perform kiyi_private.admin_probe();
  update kiyi_private.admin_leases set revoked_at=now() where session_id=sid and user_id=u;
  result=jsonb_build_object('ok',true);
 else raise exception 'ADMIN_UNKNOWN_ACTION';end if;
 -- Search query and profile PII are intentionally excluded from audit payload.
 insert into kiyi_private.admin_audit(actor,action,session_id,details) values(u,action,sid,jsonb_build_object('scope',case when action='users' then 'masked_directory' else action end));
 return result;
end $$;
revoke all on function kiyi_private.admin_probe(),kiyi_private.admin_recent_mfa(),kiyi_private.admin_authorize(text,boolean),kiyi_private.admin_command(text,jsonb) from public,anon,authenticated;
grant execute on function kiyi_private.admin_command(text,jsonb) to authenticated;
create function public.kiyi_admin_command(action text,payload jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select kiyi_private.admin_command(action,payload)$$;
revoke all on function public.kiyi_admin_command(text,jsonb) from public,anon;
grant execute on function public.kiyi_admin_command(text,jsonb) to authenticated;

-- Bootstrap is an operator-only operation, never exposed to authenticated users.
create function kiyi_private.bootstrap_admin(target_user uuid,reason text) returns void language plpgsql security definer set search_path='' as $$
begin
 perform pg_advisory_xact_lock(hashtextextended('kiyi-admin-staff',0));
 if exists(select 1 from kiyi_private.admin_memberships where role='super_admin') then raise exception 'ADMIN_ALREADY_BOOTSTRAPPED';end if;
 if length(trim(reason))<10 or not exists(select 1 from public.kiyi_profiles p join auth.users u on u.id=p.user_id where p.user_id=target_user and u.email_confirmed_at is not null) then raise exception 'ADMIN_INVALID_OWNER';end if;
 insert into kiyi_private.admin_memberships(user_id,role) values(target_user,'super_admin');
 insert into kiyi_private.admin_audit(action,entity_id,reason,details) values('bootstrap',target_user::text,reason,'{"operator_only":true}');
end $$;
revoke all on function kiyi_private.bootstrap_admin(uuid,text) from public,anon,authenticated,service_role;
notify pgrst,'reload schema';
