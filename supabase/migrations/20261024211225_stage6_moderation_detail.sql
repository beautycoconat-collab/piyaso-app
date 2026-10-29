begin;
create table kiyi_private.stage6_admin_backup as select pg_get_functiondef('kiyi_private.ops_command(jsonb)'::regprocedure) definition;
alter table kiyi_private.stage6_admin_backup enable row level security;
revoke all on kiyi_private.stage6_admin_backup from public,anon,authenticated;
CREATE OR REPLACE FUNCTION kiyi_private.ops_command(payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); r text;page text=payload->>'page';op text=coalesce(payload->>'op','list');p jsonb=coalesce(payload->'data','{}');res jsonb;old jsonb;why text;rid uuid;t uuid;item text;v int;changed int;n bigint;allowed text[];approval kiyi_private.ops_approvals;is_write boolean=op not in ('list','detail');
begin
 if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>20000 then raise exception 'ADMIN_INVALID_INPUT';end if;
 r=kiyi_private.admin_authorize(case when is_write then 'ops.write' else 'ops.read' end);
 allowed=case r when 'super_admin' then array['overview','users','plates','verifications','regions','premium','featured','catalog','packs','campaigns','ledger','gifts','orders','refunds','approvals','reports','content','appeals','announcements','settings','support','privacy','health','analytics','music','usage'] when 'admin' then array['overview','users','plates','verifications','regions','premium','featured','catalog','packs','campaigns','ledger','gifts','orders','refunds','reports','content','appeals','announcements','settings','support','privacy','health','analytics','music','usage'] when 'moderator' then array['overview','users','plates','verifications','reports','content','appeals','support'] when 'finance' then array['overview','users','ledger','gifts','orders','refunds','approvals','packs','campaigns','premium','analytics','usage'] else array['users','support','privacy','premium','appeals'] end;
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
 if op='detail' and page='reports' then
  select to_jsonb(z) into old from public.kiyi_reports z where z.id=(p->>'id')::uuid;
  if old is null then raise exception 'ADMIN_INVALID_INPUT';end if;
  res=jsonb_build_object('report',old,'content',case when old->>'subject_kind'='post' then (select to_jsonb(s) from public.kiyi_posts s where s.id=(old->>'subject_id')::uuid) when old->>'subject_kind'='comment' then (select to_jsonb(c) from public.kiyi_comments c where c.id=(old->>'subject_id')::uuid) end,
  'history',(select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc),'[]') from (select actor,action,entity_id,reason,details,created_at from kiyi_private.admin_audit where entity_id in (old->>'id',old->>'subject_id',old->>'target') and action in ('ops.reports.decide','ops.content.moderate','ops.users.sanction') order by created_at desc limit 50)a));
 elsif op='list' then
  if page='overview' then
   select c.payload||jsonb_build_object('stale',c.generated_at<now()-interval '10 minutes')into res from kiyi_private.ops_stat_cache c where c.key='overview';
   if res is null then raise exception 'ADMIN_STATISTICS_NOT_READY';end if;
   if r not in ('super_admin','admin','moderator') then res=res||jsonb_build_object('pending_reports',null);end if;
   if r in ('super_admin','admin','finance') then res=res||jsonb_build_object('usage_alerts',(select c.payload->'alerts' from kiyi_private.ops_stat_cache c where c.key='usage'));end if;
  elsif page='users' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select p.user_id,p.username,p.created_at,p.searchable,coalesce(e.verified,false) verified,coalesce(e.suspended,false) suspended,e.suspended_until,e.premium_until,p.deleted_at,left(p.profile->>'plate',2)||' •••' plate_masked from public.kiyi_profiles p left join public.kiyi_entitlements e on e.user_id=p.user_id where (coalesce(payload->>'query','')='' or p.username ilike replace(replace(payload->>'query','%','\%'),'_','\_')||'%' or p.plate_key=regexp_replace(upper(payload->>'query'),'\s','','g')) and (coalesce(payload->>'filter','all')='all' or payload->>'filter'='premium' and e.premium_until>now() or payload->>'filter'='suspended' and e.suspended or payload->>'filter'='verified' and e.verified) order by p.created_at desc,p.user_id limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='plates' then
   res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select user_id,username,case when r in ('super_admin','admin','moderator') then profile->>'plate' else left(plate_key,2)||' •••' end plate,plate_key,profile->>'car' car,profile->>'photo' photo,coalesce(profile->'photos',case when coalesce(profile->>'avatar','')<>'' then jsonb_build_array(profile->>'avatar') else '[]'::jsonb end) photos from public.kiyi_profiles where deleted_at is null and (plate_key is not null or coalesce(profile->'photos','[]'::jsonb)<>'[]'::jsonb or nullif(profile->>'avatar','') is not null) order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
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
  elsif page='reports' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from public.kiyi_reports where coalesce(payload->>'filter','all')='all' or status=payload->>'filter' order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='content' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from (select id,author,'post' kind,text,media,hidden,created from public.kiyi_posts union all select id,author,'comment',text,null,hidden,created from public.kiyi_comments)items order by created desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page in ('appeals','support','privacy') then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_cases where kind=case page when 'appeals' then 'appeal' else page end order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='announcements' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_announcements order by created_at desc limit 50 offset least(10000,greatest(0,coalesce((payload->>'offset')::int,0))))z));
  elsif page='settings' then res=kiyi_private.ops_list((select jsonb_agg(to_jsonb(z)) from(select * from kiyi_private.ops_settings order by key)z));
  elsif page in ('analytics','usage') then
   if page='usage' and r not in ('super_admin','admin','finance') then raise exception 'ADMIN_DENIED' using errcode='42501';end if;
   select c.payload||jsonb_build_object('stale',c.generated_at<now()-interval '10 minutes') into res from kiyi_private.ops_stat_cache c where c.key=page;
   if res is null then raise exception 'ADMIN_STATISTICS_NOT_READY';end if;
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
  if jsonb_typeof(p->'hidden') is distinct from 'boolean' then raise exception 'ADMIN_INVALID_INPUT';end if;
  if p->>'kind'='post' then update public.kiyi_posts set hidden=(p->>'hidden')::boolean,version=version+1,updated_at=now() where id=(p->>'id')::uuid;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_INVALID_INPUT';end if;
  elsif p->>'kind'='comment' then update public.kiyi_comments set hidden=(p->>'hidden')::boolean,version=version+1,updated_at=now() where id=(p->>'id')::uuid;get diagnostics changed=row_count;if changed<>1 then raise exception 'ADMIN_INVALID_INPUT';end if;
  elsif p->>'kind'='profile_photo' then
   if not exists(select 1 from public.kiyi_profiles where profile->>'photo'=p->>'path' or profile->>'avatar'=p->>'path' or coalesce(profile->'photos','[]'::jsonb)?(p->>'path')) then raise exception 'ADMIN_INVALID_INPUT';end if;
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
end $function$;

commit;
