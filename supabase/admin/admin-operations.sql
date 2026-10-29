-- Operations schema; additive to the verified M1 installation.
alter table public.kiyi_profiles add column deleted_at timestamptz;
alter table public.kiyi_profiles add column plate_key text generated always as (nullif(regexp_replace(upper(profile->>'plate'),'\s','','g'),'')) stored;
-- Fail rather than silently resolving existing ownership conflicts.
create unique index kiyi_unique_plate on public.kiyi_profiles(plate_key) where deleted_at is null;
alter table public.kiyi_entitlements add column featured boolean not null default false;
alter table public.kiyi_entitlements add column featured_rank integer not null default 100;
alter table public.kiyi_entitlements add column suspended_until timestamptz;
alter table public.kiyi_products add column active boolean not null default true;
alter table public.kiyi_products add column title text not null default '';
alter table public.kiyi_products add column image_url text not null default '';
alter table public.kiyi_products add column version integer not null default 1;
alter table public.kiyi_credit_packs add column active boolean not null default true;
alter table public.kiyi_credit_packs add column display_order integer not null default 0;
alter table public.kiyi_credit_packs add column version integer not null default 1;
alter table public.kiyi_regions add column active boolean not null default true;
alter table public.kiyi_regions add column version integer not null default 1;
alter table public.kiyi_posts add column hidden boolean not null default false;
alter table public.kiyi_comments add column hidden boolean not null default false;
alter table public.kiyi_reports add column assigned_to uuid references auth.users;
alter table public.kiyi_reports add column resolution text;
alter table public.kiyi_reports add column version integer not null default 1;
alter table public.kiyi_orders add column amount_kurus bigint;
alter table public.kiyi_orders add column currency text;
alter table public.kiyi_orders add column verified_at timestamptz;
create index kiyi_admin_reports_queue on public.kiyi_reports(status,created_at,id);
create index kiyi_admin_ledger_owner on public.kiyi_ledger(owner,created_at desc,id);
create index kiyi_admin_orders_owner on public.kiyi_orders(owner,created_at desc,id);
create table kiyi_private.ops_cases(id uuid primary key default gen_random_uuid(),kind text not null check(kind in ('support','privacy','appeal','plate_change')),owner uuid not null references auth.users,subject text not null,details text not null default '',status text not null default 'pending' check(status in ('pending','in_review','approved','rejected','completed')),assigned_to uuid references auth.users,decision text,related_id uuid,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),version int not null default 1);
create index ops_cases_queue on kiyi_private.ops_cases(kind,status,created_at desc,id);
create index ops_cases_owner on kiyi_private.ops_cases(owner,created_at desc);
create table kiyi_private.ops_sanctions(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users,kind text not null check(kind in ('warning','suspend','ban','restore')),until_at timestamptz,reason text not null,actor uuid not null references auth.users,created_at timestamptz not null default now());
create index ops_sanctions_user on kiyi_private.ops_sanctions(user_id,created_at desc);
create table kiyi_private.ops_settings(key text primary key,value jsonb not null,version int not null default 1,updated_at timestamptz not null default now());
insert into kiyi_private.ops_settings(key,value) values('maintenance','false'),('gifts_enabled','true'),('songs_enabled','true'),('meetups_enabled','false'),('help_text','"Destek talebini hesap bölümünden gönderebilirsin."'),('support_contact','""');
create table kiyi_private.ops_announcements(id uuid primary key default gen_random_uuid(),title text not null check(length(title) between 1 and 100),body text not null check(length(body) between 1 and 2000),category text not null check(category in ('service','security','marketing')),audience text not null check(audience in ('all','premium','free')),starts_at timestamptz not null default now(),ends_at timestamptz,active boolean not null default false,actor uuid not null references auth.users,created_at timestamptz not null default now(),version int not null default 1,check(ends_at is null or ends_at>starts_at));
create table kiyi_private.ops_campaigns(id uuid primary key default gen_random_uuid(),pack_id text not null references public.kiyi_credit_packs,title text not null,bonus integer not null check(bonus>=0),starts_at timestamptz not null,ends_at timestamptz not null,active boolean not null default false,version int not null default 1,check(ends_at>starts_at));
create table kiyi_private.ops_approvals(id uuid primary key default gen_random_uuid(),requester uuid not null references auth.users,target uuid not null references auth.users,delta bigint not null check(delta<>0 and abs(delta)<=100000),reason text not null,status text not null default 'pending' check(status in ('pending','approved','rejected')),reviewer uuid references auth.users,created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '24 hours');
create table kiyi_private.ops_activity(user_id uuid not null references auth.users,day date not null,primary key(user_id,day));
create table kiyi_private.ops_presence(user_id uuid primary key references auth.users,last_seen timestamptz not null default now());
create table kiyi_private.ops_metrics(day date not null,region text not null,samples bigint not null default 0,primary key(day,region));
create table kiyi_private.ops_events(id bigint generated always as identity primary key,kind text not null,code text not null,created_at timestamptz not null default now());
create table kiyi_private.ops_media(path text primary key,hidden boolean not null default false,reason text,actor uuid references auth.users,updated_at timestamptz not null default now());
create table kiyi_private.ops_jobs(id uuid primary key default gen_random_uuid(),kind text not null,subject uuid references auth.users,status text not null default 'pending',details jsonb not null default '{}',created_at timestamptz not null default now());
create table kiyi_private.ops_job_runs(job text primary key,last_run timestamptz,last_result jsonb);
create table kiyi_private.ops_city_catalog(id text primary key,name text not null,active boolean not null default false);
insert into kiyi_private.ops_city_catalog values('antalya','Antalya',true);
do $$declare t text;begin foreach t in array array['ops_cases','ops_sanctions','ops_settings','ops_announcements','ops_campaigns','ops_approvals','ops_activity','ops_presence','ops_metrics','ops_events','ops_media','ops_jobs','ops_job_runs','ops_city_catalog'] loop execute format('alter table kiyi_private.%I enable row level security',t);execute format('revoke all on kiyi_private.%I from public,anon,authenticated',t);end loop;end $$;
revoke all on sequence kiyi_private.ops_events_id_seq from public,anon,authenticated;
insert into kiyi_private.admin_permissions(role,permission)
select r,p from unnest(array['super_admin','admin','moderator','finance','support'])r cross join unnest(array['ops.read','ops.write'])p;

create function kiyi_private.account_active(u uuid) returns boolean language sql stable security definer set search_path='' as $$
select exists(select 1 from public.kiyi_profiles p left join public.kiyi_entitlements e on e.user_id=p.user_id where p.user_id=u and p.deleted_at is null and not(coalesce(e.suspended,false) and (e.suspended_until is null or e.suspended_until>now())))
$$;
create function kiyi_private.ops_list(rows_data jsonb) returns jsonb language sql immutable set search_path='' as $$select jsonb_build_object('items',coalesce(rows_data,'[]'))$$;

create function kiyi_private.ops_command(payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); r text;page text=payload->>'page';op text=coalesce(payload->>'op','list');p jsonb=coalesce(payload->'data','{}');res jsonb;old jsonb;why text;rid uuid;t uuid;item text;v int;changed int;n bigint;allowed text[];approval kiyi_private.ops_approvals;is_write boolean=op not in ('list','detail');
begin
 if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>20000 then raise exception 'ADMIN_INVALID_INPUT';end if;
 r=kiyi_private.admin_authorize(case when is_write then 'ops.write' else 'ops.read' end);
 allowed=case r when 'super_admin' then array['overview','users','plates','verifications','regions','premium','featured','catalog','packs','campaigns','ledger','gifts','orders','refunds','approvals','reports','content','appeals','announcements','settings','support','privacy','health','analytics','music'] when 'admin' then array['overview','users','plates','verifications','regions','premium','featured','catalog','packs','campaigns','ledger','gifts','orders','refunds','reports','content','appeals','announcements','settings','support','privacy','health','analytics','music'] when 'moderator' then array['overview','users','plates','verifications','reports','content','appeals','support'] when 'finance' then array['overview','users','ledger','gifts','orders','refunds','approvals','packs','campaigns','premium','analytics'] else array['users','support','privacy','premium','appeals'] end;
 if page is null or not(page=any(allowed)) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
 if is_write then
  if r='support' and page not in ('support','privacy') or r='finance' and page not in ('approvals','refunds') or r='moderator' and page not in ('reports','content','verifications','appeals','users','support') then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  why=trim(coalesce(p->>'reason',''));rid=(p->>'request_id')::uuid;
  if length(why) not between 10 and 500 or rid is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  perform pg_advisory_xact_lock(hashtextextended('kiyi-admin-ops',0));
  select a.result into res from kiyi_private.admin_requests a where actor=u and request_id=rid;
  if found then
   if not exists(select 1 from kiyi_private.admin_requests a where actor=u and request_id=rid and a.payload=ops_command.payload) then raise exception 'ADMIN_REQUEST_CONFLICT';end if;
   return res;
  end if;
  if page='featured' and r<>'super_admin' then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  if page in ('approvals','premium','packs','campaigns','settings','regions','featured','privacy') and not kiyi_private.admin_recent_mfa() then raise exception 'ADMIN_REAUTH_REQUIRED' using errcode='42501';end if;
 end if;
 if p?'user_id' then t=(p->>'user_id')::uuid;end if;
 if p?'version' then v=(p->>'version')::int;end if;
 if op='list' then
  if page='overview' then
   res=jsonb_build_object('as_of',now(),'users',(select count(*) from public.kiyi_profiles where deleted_at is null),'dau',(select count(*) from kiyi_private.ops_activity where day=(now() at time zone 'Europe/Istanbul')::date),'wau',(select count(distinct user_id) from kiyi_private.ops_activity where day>=(now() at time zone 'Europe/Istanbul')::date-6),'mau',(select count(distinct user_id) from kiyi_private.ops_activity where day>=(now() at time zone 'Europe/Istanbul')::date-29),'online',(select count(*) from kiyi_private.ops_presence where last_seen>now()-interval '90 seconds'),'map_active',(select count(*) from public.kiyi_positions l join public.kiyi_privacy q using(user_id) join public.kiyi_regions rg on rg.id=l.region where q.sharing and l.received_at>now()-interval '90 seconds' and rg.active and kiyi_private.account_active(l.user_id)),'ghost_active',(select count(*) from public.kiyi_positions l join public.kiyi_privacy q using(user_id) where q.sharing and q.ghost and l.received_at>now()-interval '90 seconds' and kiyi_private.account_active(l.user_id)),'premium',(select count(*) from public.kiyi_entitlements where premium_until>now() and kiyi_private.account_active(user_id)),'pending_reports',case when r in ('super_admin','admin','moderator') then (select count(*) from public.kiyi_reports where status='pending') else null end,'gifts',(select count(*) from public.kiyi_gifts where product<>'song'),'songs',(select count(*) from public.kiyi_gifts where product='song'),'payments_connected',false,'activity_since',(select min(day) from kiyi_private.ops_activity));
  elsif page='users' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select p.user_id,p.username,p.created_at,p.searchable,coalesce(e.verified,false) verified,coalesce(e.suspended,false) suspended,e.suspended_until,e.premium_until,p.deleted_at,left(p.profile->>'plate',2)||' •••' plate_masked from public.kiyi_profiles p left join public.kiyi_entitlements e on e.user_id=p.user_id where (coalesce(payload->>'query','')='' or p.username ilike replace(replace(payload->>'query','%','\%'),'_','\_')||'%' or p.plate_key=regexp_replace(upper(payload->>'query'),'\s','','g')) and (coalesce(payload->>'filter','all')='all' or payload->>'filter'='premium' and e.premium_until>now() or payload->>'filter'='suspended' and e.suspended or payload->>'filter'='verified' and e.verified) order by p.created_at desc,p.user_id limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='plates' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select user_id,username,case when r in ('super_admin','admin','moderator') then profile->>'plate' else left(plate_key,2)||' •••' end plate,plate_key,profile->>'car' car,profile->>'photo' photo from public.kiyi_profiles where plate_key is not null and deleted_at is null order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='verifications' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select vr.*,p.username from public.kiyi_verifications vr join public.kiyi_profiles p using(user_id) order by vr.created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='regions' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select rg.id,rg.name,rg.city,rg.premium,rg.active,rg.version,(select count(*) from public.kiyi_positions l join public.kiyi_privacy q using(user_id) where region=rg.id and received_at>now()-interval '90 seconds' and q.sharing and kiyi_private.account_active(l.user_id)) active_vehicles from public.kiyi_regions rg order by name)z));
  elsif page in ('premium','featured') then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select p.user_id,p.username,e.premium_until,coalesce(e.verified,false) verified,coalesce(e.featured,false) featured,coalesce(e.featured_rank,100) featured_rank,coalesce(q.ghost,false) ghost from public.kiyi_profiles p left join public.kiyi_entitlements e on e.user_id=p.user_id left join public.kiyi_privacy q on q.user_id=p.user_id where p.deleted_at is null order by coalesce(e.featured_rank,100),p.created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='catalog' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from public.kiyi_products order by kind,id)z));
  elsif page='packs' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from public.kiyi_credit_packs order by display_order,base)z));
  elsif page='campaigns' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_campaigns order by starts_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='ledger' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from public.kiyi_ledger where t is null or owner=t order by created_at desc,id desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='gifts' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select id,sender,recipient,product,credits,created from public.kiyi_gifts where t is null or sender=t or recipient=t order by created desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='orders' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select id,owner,provider,pack_id,status,created_at,amount_kurus,currency,verified_at from public.kiyi_orders where t is null or owner=t order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='refunds' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_cases where kind='support' and subject='refund_review' order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='approvals' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_approvals order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='reports' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from public.kiyi_reports order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='content' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from (select id,author,'post' kind,text,media,hidden,created from public.kiyi_posts union all select id,author,'comment',text,null,hidden,created from public.kiyi_comments)items order by created desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page in ('appeals','support','privacy') then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_cases where kind=case page when 'appeals' then 'appeal' else page end order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='announcements' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_announcements order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='settings' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_settings order by key)z));
  elsif page='analytics' then
   res=jsonb_build_object('daily',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select day,count(*) active_users from kiyi_private.ops_activity where day>=current_date-29 group by day order by day)z),'gift_top',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select product,count(*) sent,sum(credits) credits from public.kiyi_gifts group by product order by count(*) desc)z),'regions',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select * from kiyi_private.ops_metrics where day>=current_date-29 order by day desc)z),'revenue',null,'note','Gelir sağlayıcısı bağlı değil. Aktiflik yalnız ölçümün başladığı tarihten itibaren tutulur.');
  elsif page='health' then
   res=jsonb_build_object('database','connected','as_of',now(),'rpc','Postgres RPC','payment_verification','not_connected','push','not_connected','backups','Altyapı panelinden doğrulanmalı','metrics',(select jsonb_build_object('stale_positions',count(*) filter(where received_at<now()-interval '5 minutes'),'positions',count(*)) from public.kiyi_positions),'jobs',(select coalesce(jsonb_agg(to_jsonb(j)),'[]') from kiyi_private.ops_job_runs j),'queue',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select id,kind,status,created_at from kiyi_private.ops_jobs order by created_at desc limit 50)z),'errors',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select kind,code,count(*) total from kiyi_private.ops_events where created_at>now()-interval '1 day' group by kind,code)z));
  elsif page='music' then
   res=jsonb_build_object('song_price',(select credits from public.kiyi_products where id='song'),'source','Spotify / Apple bağlantı kataloğu','playback',false,'spotify_live_verified',false,'recent_links',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select id,song->>'title' title,song->>'artist' artist,song->>'url' url,created from public.kiyi_gifts where product='song' order by created desc limit 50)z));
  else raise exception 'ADMIN_UNKNOWN_ACTION';end if;
 elsif op='detail' and page='users' then
  if not exists(select 1 from public.kiyi_profiles where user_id=t) then raise exception 'ADMIN_INVALID_INPUT';end if;
  res=jsonb_build_object('profile',(select jsonb_build_object('id',user_id,'username',username,'created_at',created_at,'name',profile->>'ownerName','bio',profile->>'bio','car',profile->>'car','plate',case when r in ('super_admin','admin','moderator') then profile->>'plate' else null end,'searchable',searchable,'deleted_at',deleted_at) from public.kiyi_profiles where user_id=t),'entitlements',(select to_jsonb(e) from public.kiyi_entitlements e where user_id=t),'followers',(select count(*) from public.kiyi_follows where target=t),'following',(select count(*) from public.kiyi_follows where follower=t),'balance',case when r in ('super_admin','admin','finance') then (select balance from public.kiyi_wallets where user_id=t) else null end,'sanctions',case when r in ('super_admin','admin','moderator') then (select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select * from kiyi_private.ops_sanctions where user_id=t order by created_at desc limit 30)z) else null end,'gifts',(select count(*) from public.kiyi_gifts where sender=t or recipient=t));
 elsif page='users' and op='sanction' then
  if t is null or t=u or not kiyi_private.account_active(t) and p->>'kind'<>'restore' or exists(select 1 from kiyi_private.admin_memberships where user_id=t and active) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  item=p->>'kind';if item not in ('warning','suspend','ban','restore') or item is null or r='moderator' and item in ('ban','restore') or item='ban' and r<>'super_admin' then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  if item in ('ban','restore') and not kiyi_private.admin_recent_mfa() then raise exception 'ADMIN_REAUTH_REQUIRED' using errcode='42501';end if;
  if item='suspend' and ((p->>'until_at')::timestamptz is null or (p->>'until_at')::timestamptz not between now() and now()+interval '30 days' or r='moderator' and (p->>'until_at')::timestamptz>now()+interval '24 hours') then raise exception 'ADMIN_INVALID_INPUT';end if;
  insert into kiyi_private.ops_sanctions(user_id,kind,until_at,reason,actor) values(t,item,case when item='suspend' then (p->>'until_at')::timestamptz else null end,why,u);
  if item<>'warning' then insert into public.kiyi_entitlements(user_id,suspended,suspended_until) values(t,item<>'restore',case when item='suspend' then (p->>'until_at')::timestamptz else null end) on conflict(user_id)do update set suspended=excluded.suspended,suspended_until=excluded.suspended_until;delete from public.kiyi_positions where user_id=t;update public.kiyi_privacy set sharing=false where user_id=t;end if;
 elsif page='reports' and op='decide' then
  if p->>'status' not in ('pending','in_review','resolved','dismissed') or p->>'status' is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  update public.kiyi_reports set status=p->>'status',resolution=why,assigned_to=u,version=version+1 where id=(p->>'id')::uuid and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
 elsif page='content' and op='moderate' then
  if p->>'kind'='post' then update public.kiyi_posts set hidden=(p->>'hidden')::boolean where id=(p->>'id')::uuid;
  elsif p->>'kind'='comment' then update public.kiyi_comments set hidden=(p->>'hidden')::boolean where id=(p->>'id')::uuid;
  elsif p->>'kind'='profile_photo' then
   if not exists(select 1 from public.kiyi_profiles where profile->>'photo'=p->>'path' or profile->>'avatar'=p->>'path') then raise exception 'ADMIN_INVALID_INPUT';end if;
   insert into kiyi_private.ops_media(path,hidden,reason,actor) values(p->>'path',(p->>'hidden')::boolean,why,u) on conflict(path) do update set hidden=excluded.hidden,reason=excluded.reason,actor=u,updated_at=now();
  else raise exception 'ADMIN_INVALID_INPUT';end if;
 elsif page='plates' and op='decide_change' then
  select to_jsonb(c) into old from kiyi_private.ops_cases c where id=(p->>'id')::uuid and kind='plate_change' and status='pending' for update;
  if old is null or (old->>'version')::int<>v or p->>'status' not in ('approved','rejected') then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  if p->>'status'='approved' then
   if length(old->>'subject') not between 3 and 30 then raise exception 'ADMIN_INVALID_INPUT';end if;
   update public.kiyi_profiles set profile=jsonb_set(profile,'{plate}',old->'subject')where user_id=(old->>'owner')::uuid and deleted_at is null;
   update public.kiyi_verifications set status='pending',plate=old->>'subject' where user_id=(old->>'owner')::uuid;
  end if;
  update kiyi_private.ops_cases set status=p->>'status',decision=why,assigned_to=u,updated_at=now(),version=version+1 where id=(old->>'id')::uuid;
 elsif page='verifications' and op='decide' then
  if p->>'status' not in ('approved','rejected') or p->>'status' is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  update public.kiyi_verifications set status=p->>'status' where user_id=t and status='pending';get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  -- Ownership application approval is separate from a public account badge.
 elsif page='featured' and op='update' then
  if not exists(select 1 from public.kiyi_profiles where user_id=t and deleted_at is null) then raise exception 'ADMIN_INVALID_INPUT';end if;
  insert into public.kiyi_entitlements(user_id,featured,featured_rank,verified) values(t,(p->>'featured')::boolean,greatest(1,least(9999,(p->>'rank')::int)),(p->>'verified')::boolean) on conflict(user_id) do update set featured=excluded.featured,featured_rank=excluded.featured_rank,verified=excluded.verified;
 elsif page='premium' and op='grant' then
  if r<>'super_admin' or t=u or not exists(select 1 from public.kiyi_profiles where user_id=t and deleted_at is null) or (p->>'until_at')::timestamptz not between now() and now()+interval '1 year' or nullif(p->>'until_at','') is null then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  insert into public.kiyi_entitlements(user_id,premium_until)values(t,(p->>'until_at')::timestamptz) on conflict(user_id)do update set premium_until=excluded.premium_until;
 elsif page='regions' and op='update' then
  update public.kiyi_regions set active=(p->>'active')::boolean,premium=(p->>'premium')::boolean,version=version+1 where id=p->>'id' and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  if not(p->>'active')::boolean then delete from public.kiyi_positions where region=p->>'id';end if;
 elsif page='catalog' and op in ('update','create') then
  if nullif(p->>'title','') is null or length(p->>'title')>100 or (p->>'credits')::int not between 1 and 100000 or coalesce(p->>'image_url','')<>'' and (p->>'image_url')!~'^https://' then raise exception 'ADMIN_INVALID_INPUT';end if;
  if op='create' then
   if p->>'id' !~'^[a-z][a-z0-9_-]{2,40}$' then raise exception 'ADMIN_INVALID_INPUT';end if;
   insert into public.kiyi_products(id,kind,credits,title,image_url,active)values(p->>'id','gift',(p->>'credits')::int,p->>'title',coalesce(p->>'image_url',''),(p->>'active')::boolean);
  else
   update public.kiyi_products set credits=(p->>'credits')::int,title=p->>'title',image_url=coalesce(p->>'image_url',''),active=(p->>'active')::boolean,version=version+1 where id=p->>'id' and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  end if;
 elsif page='packs' and op='update' then
  if (p->>'base')::int not between 1 and 100000 or (p->>'bonus')::int not between 0 and 100000 then raise exception 'ADMIN_INVALID_INPUT';end if;
  -- price_kurus intentionally cannot be changed here: store integration not connected.
  update public.kiyi_credit_packs set base=(p->>'base')::int,bonus=(p->>'bonus')::int,active=(p->>'active')::boolean,display_order=(p->>'display_order')::int,version=version+1 where id=p->>'id' and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
 elsif page='campaigns' and op='create' then
  insert into kiyi_private.ops_campaigns(pack_id,title,bonus,starts_at,ends_at,active)values(p->>'pack_id',left(p->>'title',100),(p->>'bonus')::int,(p->>'starts_at')::timestamptz,(p->>'ends_at')::timestamptz,(p->>'active')::boolean);
 elsif page='campaigns' and op='toggle' then
  update kiyi_private.ops_campaigns set active=(p->>'active')::boolean,version=version+1 where id=(p->>'id')::uuid and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
 elsif page='settings' and op='update' then
  item=p->>'key';
  if item in ('maintenance','gifts_enabled','songs_enabled') then if jsonb_typeof(p->'value')<>'boolean' then raise exception 'ADMIN_INVALID_INPUT';end if;
  elsif item in ('help_text','support_contact') then if jsonb_typeof(p->'value')<>'string' or length(p->>'value')>2000 then raise exception 'ADMIN_INVALID_INPUT';end if;
  else raise exception 'ADMIN_INVALID_INPUT';end if;
  update kiyi_private.ops_settings set value=p->'value',updated_at=now(),version=version+1 where key=item and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
 elsif page='announcements' and op='create' then
  insert into kiyi_private.ops_announcements(title,body,category,audience,starts_at,ends_at,active,actor)values(p->>'title',p->>'body',p->>'category',p->>'audience',coalesce(nullif(p->>'starts_at','')::timestamptz,now()),nullif(p->>'ends_at','')::timestamptz,(p->>'active')::boolean,u);
 elsif page='announcements' and op='toggle' then
  update kiyi_private.ops_announcements set active=(p->>'active')::boolean,version=version+1 where id=(p->>'id')::uuid and version=v;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_VERSION_CONFLICT';end if;
 elsif page='approvals' and op='request' then
  if t=u or not exists(select 1 from public.kiyi_wallets where user_id=t) then raise exception 'ADMIN_INVALID_INPUT';end if;
  insert into kiyi_private.ops_approvals(requester,target,delta,reason) values(u,t,(p->>'delta')::bigint,why) returning jsonb_build_object('id',id,'status',status) into res;
 elsif page='approvals' and op in ('approve','reject') then
  select * into approval from kiyi_private.ops_approvals where id=(p->>'id')::uuid for update;
  if approval.id is null or approval.status<>'pending' or approval.expires_at<now() or approval.requester=u or approval.target=u then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  if op='approve' then
   perform pg_advisory_xact_lock(hashtextextended('kiyi:'||approval.target::text,0));
   update public.kiyi_wallets set balance=balance+approval.delta where user_id=approval.target and balance+approval.delta>=0;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_INSUFFICIENT_BALANCE';end if;
   insert into public.kiyi_ledger(owner,request_id,amount,kind,reference) values(approval.target,approval.id,approval.delta,'admin_adjustment',approval.reason);
  end if;
  update kiyi_private.ops_approvals set status=case when op='approve' then 'approved' else 'rejected' end,reviewer=u where id=approval.id;
 elsif page in ('support','privacy','appeals','refunds') and op='create' then
  if not exists(select 1 from public.kiyi_profiles where user_id=t) then raise exception 'ADMIN_INVALID_INPUT';end if;
  insert into kiyi_private.ops_cases(kind,owner,subject,details,related_id)values(case when page='appeals' then 'appeal' when page='refunds' then 'support' else page end,t,case when page='refunds' then 'refund_review' else left(p->>'subject',100) end,left(coalesce(p->>'details',''),2000),nullif(p->>'related_id','')::uuid);
 elsif page in ('support','privacy','appeals','refunds') and op='decide' then
  if p->>'status' not in ('in_review','approved','rejected','completed') or p->>'status' is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  select to_jsonb(c) into old from kiyi_private.ops_cases c where id=(p->>'id')::uuid and kind=case when page='appeals' then 'appeal' when page='refunds' then 'support' else page end for update;
  if old is null or (old->>'version')::int<>v then raise exception 'ADMIN_VERSION_CONFLICT';end if;
  if page='appeals' and exists(select 1 from kiyi_private.ops_sanctions where id=(old->>'related_id')::uuid and actor=u) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  if page='privacy' and p->>'status'='completed' and old->>'subject'='delete_account' then raise exception 'ADMIN_DELETION_WORKFLOW_REQUIRED';end if;
  if page='refunds' and p->>'status'='completed' then raise exception 'ADMIN_PROVIDER_REQUIRED';end if;
  update kiyi_private.ops_cases set status=p->>'status',decision=why,assigned_to=u,updated_at=now(),version=version+1 where id=(p->>'id')::uuid;
 elsif page='privacy' and op='erase' then
  if r<>'super_admin' then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  select to_jsonb(c) into old from kiyi_private.ops_cases c where id=(p->>'id')::uuid and kind='privacy' and subject='delete_account' and status in ('pending','approved','in_review') for update;
  if old is null or (old->>'owner')::uuid=u or exists(select 1 from kiyi_private.admin_memberships where user_id=(old->>'owner')::uuid and active) then raise exception 'ADMIN_INVALID_INPUT';end if;
  t=(old->>'owner')::uuid;
  -- Revoke Kıyı visibility immediately; retain finance and shared Auth identity.
  update public.kiyi_profiles set deleted_at=now(),searchable=false,profile='{}',username='deleted_'||left(replace(t::text,'-',''),22) where user_id=t;
  insert into public.kiyi_entitlements(user_id,suspended)values(t,true)on conflict(user_id)do update set suspended=true,featured=false,verified=false,premium_until=null;
  update public.kiyi_privacy set sharing=false,approved='{}' where user_id=t;delete from public.kiyi_positions where user_id=t;
  update public.kiyi_posts set text='',hidden=true,music=null,poll=null where author=t;update public.kiyi_comments set text='[silindi]',hidden=true where author=t;
  delete from public.kiyi_follows where follower=t or target=t;delete from public.kiyi_favorites where owner=t or target=t;delete from public.kiyi_visits where owner=t or visitor=t;
  insert into kiyi_private.ops_jobs(kind,subject,details)values('storage_erasure',t,jsonb_build_object('case_id',old->>'id','bucket','kiyi-media'));
  update kiyi_private.ops_cases set status='in_review',decision=why,assigned_to=u,updated_at=now(),version=version+1 where id=(old->>'id')::uuid;
  res=jsonb_build_object('ok',true,'status','storage_erasure_pending');
 else raise exception 'ADMIN_UNKNOWN_ACTION';end if;
 if page='users' and op='detail' then res=res||jsonb_build_object('purchase_history',(select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select id,provider,pack_id,status,created_at from public.kiyi_orders where owner=t order by created_at desc limit 20)z),'gift_history',case when r in ('super_admin','admin','finance') then (select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select id,sender,recipient,product,credits,created from public.kiyi_gifts where sender=t or recipient=t order by created desc limit 30)z) else null end,'credit_history',case when r in ('super_admin','admin','finance') then (select coalesce(jsonb_agg(to_jsonb(z)),'[]') from(select amount,kind,reference,created_at from public.kiyi_ledger where owner=t order by created_at desc limit 30)z) else null end);end if;
 if page='plates' and op='list' then res=res||jsonb_build_object('changes',(select coalesce(jsonb_agg(to_jsonb(c)),'[]') from kiyi_private.ops_cases c where kind='plate_change' and status='pending'));end if;
 if page='privacy' and op='list' then res=res||jsonb_build_object('jobs',(select coalesce(jsonb_agg(to_jsonb(j)),'[]') from kiyi_private.ops_jobs j where kind='storage_erasure' and status='pending'));end if;
 if res is null then res=jsonb_build_object('ok',true);end if;
 insert into kiyi_private.admin_audit(actor,action,entity_id,reason,details,request_id,session_id)values(u,'ops.'||page||'.'||op,coalesce(p->>'id',p->>'user_id',p->>'key'),why,case when is_write then jsonb_build_object('input',p-'request_id'-'details'-'body','before',old) else jsonb_build_object('scope',page) end,rid,(auth.jwt()->>'session_id')::uuid);
 if is_write then insert into kiyi_private.admin_requests values(u,rid,'ops',payload,res);end if;
 return res;
end $$;
revoke all on function kiyi_private.account_active(uuid),kiyi_private.ops_list(jsonb),kiyi_private.ops_command(jsonb) from public,anon,authenticated;
grant execute on function kiyi_private.ops_command(jsonb) to authenticated;
-- Preserve the M1 dispatcher for its existing actions; new actions have a separate gate.
create or replace function public.kiyi_admin_command(action text,payload jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select case when action='ops' then kiyi_private.ops_command(payload) else kiyi_private.admin_command(action,payload) end$$;

create function kiyi_private.user_operations(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();k text;res jsonb;ms bigint=(extract(epoch from now())*1000)::bigint;
begin
 if u is null or not exists(select 1 from auth.users where id=u) or jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>10000 then raise exception 'Giriş yapmalısın.' using errcode='42501';end if;
 if action='ops_config' then
  res=jsonb_build_object('settings',(select jsonb_object_agg(key,value) from kiyi_private.ops_settings),'products',(select jsonb_agg(to_jsonb(p)) from public.kiyi_products p where active),'packs',(select jsonb_agg(to_jsonb(z)) from(select p.*,p.bonus+coalesce((select max(c.bonus) from kiyi_private.ops_campaigns c where c.pack_id=p.id and c.active and now() between c.starts_at and c.ends_at),0) effective_bonus from public.kiyi_credit_packs p where active order by display_order,base)z),'announcements',(select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'title',a.title,'body',a.body,'category',a.category)),'[]') from kiyi_private.ops_announcements a where a.active and a.starts_at<=now() and (a.ends_at is null or a.ends_at>now()) and (a.audience='all' or a.audience='premium' and kiyi_private.premium(u) or a.audience='free' and not kiyi_private.premium(u)) and (a.category<>'marketing' or coalesce((select (preferences->>'marketing')::boolean from public.kiyi_preferences where user_id=u),false))));return res;
 elsif action='sanctions_mine' then return kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select id,kind,until_at,reason,created_at from kiyi_private.ops_sanctions where user_id=u order by created_at desc limit 50)z));
 elsif action='cases_mine' then return kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select id,kind,subject,details,status,decision,related_id,created_at from kiyi_private.ops_cases where owner=u order by created_at desc limit 50)z));
 end if;
 if (select count(*) from kiyi_private.ops_cases where owner=u and created_at>now()-interval '1 hour')>=5 then raise exception 'Talep sınırına ulaştın.';end if;
 if length(trim(coalesce(payload->>'details','')))not between 10 and 2000 then raise exception 'Açıklaman 10–2000 karakter olmalı.';end if;
 k=case action when 'support_create' then 'support' when 'privacy_request' then 'privacy' when 'appeal_create' then 'appeal' when 'plate_change_request' then 'plate_change' end;
 if k is null then raise exception 'Desteklenmeyen işlem.';end if;
 if k='privacy' and coalesce(payload->>'subject','') not in ('delete_account','data_access') then raise exception 'Talep türünü kontrol et.';end if;
 if k='appeal' and not exists(select 1 from kiyi_private.ops_sanctions where user_id=u and id=(payload->>'related_id')::uuid) then raise exception 'İtiraz edilecek karar bulunamadı.';end if;
 insert into kiyi_private.ops_cases(kind,owner,subject,details,related_id)values(k,u,left(coalesce(payload->>'subject','Destek'),100),payload->>'details',nullif(payload->>'related_id','')::uuid) returning jsonb_build_object('id',id,'status',status) into res;return res;
end $$;
revoke all on function kiyi_private.user_operations(text,jsonb) from public,anon,authenticated;

create function kiyi_private.ops_cleanup() returns jsonb language plpgsql security definer set search_path='' as $$declare n int;begin
 delete from public.kiyi_positions where received_at<now()-interval '5 minutes';get diagnostics n=row_count;
 delete from kiyi_private.ops_presence where last_seen<now()-interval '5 minutes';
 delete from public.kiyi_visits where visited<extract(epoch from now()-interval '30 days')*1000;
 delete from kiyi_private.ops_events where created_at<now()-interval '30 days';
 delete from kiyi_private.ops_activity where day<current_date-400;
 insert into kiyi_private.ops_job_runs(job,last_run,last_result)values('privacy_cleanup',now(),jsonb_build_object('positions_removed',n))on conflict(job)do update set last_run=excluded.last_run,last_result=excluded.last_result;
 return jsonb_build_object('positions_removed',n);
end $$;
revoke all on function kiyi_private.ops_cleanup() from public,anon,authenticated,service_role;

create function kiyi_private.admin_media_allowed(path text,deleting boolean default false) returns boolean language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();r text;ok boolean;
begin
 if u is null or auth.jwt()->>'aal' is distinct from 'aal2' then return false;end if;
 select role into r from kiyi_private.admin_memberships where user_id=u and active;
 if r not in ('super_admin','admin','moderator') or r is null then return false;end if;
 if not exists(select 1 from auth.sessions where id=(auth.jwt()->>'session_id')::uuid and user_id=u) or not exists(select 1 from kiyi_private.admin_leases where session_id=(auth.jwt()->>'session_id')::uuid and user_id=u and revoked_at is null and last_seen>now()-interval '15 minutes' and expires_at>now())then return false;end if;
 if deleting then ok=r='super_admin' and exists(select 1 from kiyi_private.ops_jobs where kind='storage_erasure' and status='pending' and subject::text=split_part(path,'/',1));
 else ok=exists(select 1 from public.kiyi_posts where media=path) or exists(select 1 from public.kiyi_profiles where profile->>'avatar'=path or profile->>'photo'=path) or exists(select 1 from kiyi_private.ops_jobs where kind='storage_erasure' and status='pending' and subject::text=split_part(path,'/',1));end if;
 if ok then insert into kiyi_private.admin_audit(actor,action,entity_id,session_id)values(u,case when deleting then 'media.delete' else 'media.read' end,path,(auth.jwt()->>'session_id')::uuid);end if;
 return ok;
end $$;
revoke all on function kiyi_private.admin_media_allowed(text,boolean) from public,anon;
grant execute on function kiyi_private.admin_media_allowed(text,boolean) to authenticated;
create policy kiyi_admin_media_read on storage.objects for select to authenticated using(bucket_id='kiyi-media' and kiyi_private.admin_media_allowed(name,false));
create policy kiyi_admin_media_delete on storage.objects for delete to authenticated using(bucket_id='kiyi-media' and kiyi_private.admin_media_allowed(name,true));
create function kiyi_private.admin_media_command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare r text;job kiyi_private.ops_jobs;res jsonb;
begin
 r=kiyi_private.admin_authorize('ops.write');
 if action='sign' then
  if not kiyi_private.admin_media_allowed(payload->>'path',false) then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
  return jsonb_build_object('path',payload->>'path');
 end if;
 if r<>'super_admin' or not kiyi_private.admin_recent_mfa() then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
 select * into job from kiyi_private.ops_jobs where id=(payload->>'job_id')::uuid and kind='storage_erasure' and status='pending' for update;
 if job.id is null then raise exception 'ADMIN_INVALID_INPUT';end if;
 if action='batch' then return jsonb_build_object('paths',(select coalesce(jsonb_agg(name),'[]') from(select name from storage.objects where bucket_id='kiyi-media' and split_part(name,'/',1)=job.subject::text limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
 elsif action='finish' then
  if exists(select 1 from storage.objects where bucket_id='kiyi-media' and split_part(name,'/',1)=job.subject::text)then raise exception 'ADMIN_DELETION_WORKFLOW_REQUIRED';end if;
  update kiyi_private.ops_jobs set status='completed' where id=job.id;
  update kiyi_private.ops_cases set status='completed',updated_at=now(),version=version+1 where id=(job.details->>'case_id')::uuid;
  delete from public.kiyi_preferences where user_id=job.subject;delete from public.kiyi_devices where owner=job.subject;
  update public.kiyi_posts set media=null where author=job.subject;
  insert into kiyi_private.admin_audit(actor,action,entity_id,reason,session_id)values(auth.uid(),'privacy.erase.completed',job.subject::text,'Kıyı profil ve medya silme işi tamamlandı.',(auth.jwt()->>'session_id')::uuid);
  return jsonb_build_object('ok',true);
 else raise exception 'ADMIN_UNKNOWN_ACTION';end if;
end $$;
revoke all on function kiyi_private.admin_media_command(text,jsonb) from public,anon;
grant execute on function kiyi_private.admin_media_command(text,jsonb) to authenticated;
create or replace function public.kiyi_admin_command(action text,payload jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select case when action='ops' then kiyi_private.ops_command(payload) when action='media' then kiyi_private.admin_media_command(payload->>'op',payload) else kiyi_private.admin_command(action,payload) end$$;
