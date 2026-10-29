create index kiyi_positions_viewport on public.kiyi_positions using gist(point(lng,lat));
create function kiyi_private.viewport_map(viewer uuid,p jsonb)returns jsonb language plpgsql security definer set search_path='' as $$
declare w float8=(p->>'west')::float8;e float8=(p->>'east')::float8;s float8=(p->>'south')::float8;n float8=(p->>'north')::float8;z float8=(p->>'zoom')::float8;lim integer;result jsonb;
begin
 if w is null or e is null or s is null or n is null or z is null or not(w>=-180 and e<=180 and w<e and s>=-90 and n<=90 and s<n and z>=0 and z<=24) then raise exception 'INVALID_MAP_VIEWPORT';end if;
 lim=case when z<13 then 100 when z<15 then 200 else 400 end;
 with eligible as materialized(
 select l.*,q.ghost,r.premium from public.kiyi_positions l join public.kiyi_privacy q using(user_id) join public.kiyi_regions r on r.id=l.region
 where point(l.lng,l.lat)<@box(point(w,s),point(e,n)) and l.received_at>now()-interval '90 seconds' and (p->>'region'='all' or l.region=coalesce(p->>'region','konyaalti')) and q.sharing and r.active and kiyi_private.account_active(l.user_id) and not kiyi_private.blocked(viewer,l.user_id) and (q.visibility='all' or l.user_id=viewer or viewer=any(q.approved))
 ), counts as(select region,count(*) c from eligible group by region), totals as(select count(*) total from eligible),
 ranked as(select x.*,row_number()over(partition by x.region order by md5(x.user_id::text)) rank from eligible x),
 fair as(select user_id from ranked order by rank,region limit lim/2),
 remaining as(select x.* from ranked x where user_id not in(select user_id from fair)),
 remcounts as(select region,count(*) c from remaining group by region),
 weights as(select region,(lim-(select count(*)from fair))*c::numeric/(select count(*)from remaining) weight from remcounts),
 quotas as(select region,floor(weight)::int+case when row_number()over(order by weight-floor(weight) desc,region)<=lim-(select count(*)from fair)-(select coalesce(sum(floor(weight)),0)from weights)then 1 else 0 end quota from weights),
 remrank as(select x.*,row_number()over(partition by region order by md5(user_id::text)) nr from remaining x),
 sample as(select user_id from fair union all select x.user_id from remrank x join quotas q using(region)where nr<=q.quota),
 chosen as(select x.* from ranked x where (z>=17 and (not(p?'after') or x.user_id>(p->>'after')::uuid)) or (z<17 and ((select total from totals)<=200 or x.user_id in(select user_id from sample))) order by x.user_id limit case when z>=17 then 200 else greatest(200,lim)end)
 select jsonb_build_object('people',coalesce((select jsonb_agg(
 case when kiyi_private.premium(viewer) or (not x.premium and not x.ghost) or (not x.ghost and exists(select 1 from public.kiyi_entitlements where user_id=x.user_id and featured)) or x.user_id=viewer
 then kiyi_private.person(x.user_id) else jsonb_build_object('id',md5(viewer::text||x.user_id::text||current_date::text)::uuid,'ghost',true,'username','hayalet','plate','** ***') end ||
 jsonb_build_object('pos',jsonb_build_array(case when x.user_id=viewer then x.lat else round(x.lat::numeric,3)::float8 end,case when x.user_id=viewer then x.lng else round(x.lng::numeric,3)::float8 end),'heading',x.heading,'updated',extract(epoch from x.received_at)*1000) order by x.user_id)from chosen x),'[]'),'total',(select total from totals),'sampled',z<17 and (select total from totals)>greatest(200,lim),'next',case when z>=17 and (select count(*)from chosen)=200 then (select user_id::text from chosen order by user_id desc limit 1)else null end)into result;
 return result;
end $$;
revoke all on function kiyi_private.viewport_map(uuid,jsonb) from public,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION kiyi_private.command(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid();t uuid;rid uuid;prod text;cost integer;bal bigint;existing jsonb;item text;input_profile jsonb;person jsonb;arr jsonb;postid uuid;post_record public.kiyi_posts;out jsonb;ms bigint=(extract(epoch from clock_timestamp())*1000)::bigint;is_premium boolean;reg text;la double precision;lo double precision;pref jsonb;names jsonb;v text;
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'Giriş yapmalısın.' using errcode='42501';end if;
 if action in ('ops_config','support_create','privacy_request','appeal_create','sanctions_mine','cases_mine','plate_change_request') then return kiyi_private.user_operations(action,payload);end if;
 if exists(select 1 from public.kiyi_profiles where user_id=u and deleted_at is not null) then raise exception 'Kıyı hesabın silinmiş.' using errcode='42501';end if;
 if coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='maintenance'),false) then raise exception 'Kıyı kısa süreli bakımda. Biraz sonra yeniden dene.';end if;
 if exists(select 1 from public.kiyi_entitlements where user_id=u and suspended and (suspended_until is null or suspended_until>now())) then raise exception 'Hesabın kullanıma kapalı.' using errcode='42501';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 insert into public.kiyi_profiles(user_id,username) values(u,'kiyi_'||left(replace(u::text,'-',''),24)) on conflict(user_id) do nothing;
 insert into public.kiyi_wallets values(u,0) on conflict do nothing;
 insert into public.kiyi_appearance(user_id) values(u) on conflict do nothing;
 insert into public.kiyi_privacy(user_id) values(u) on conflict do nothing;
 is_premium=kiyi_private.premium(u);
 insert into kiyi_private.ops_presence(user_id,last_seen) values(u,now()) on conflict(user_id)do update set last_seen=now() where kiyi_private.ops_presence.last_seen<now()-interval '1 minute';
 if action in ('bundle','profile','post_create','gift') then insert into kiyi_private.ops_activity values(u,(now() at time zone 'Europe/Istanbul')::date) on conflict do nothing;end if;
 if payload?'target' then t=(payload->>'target')::uuid;end if;
 if action='profile_photos' then
  t=coalesce(t,u);
  if t<>u and (not exists(select 1 from public.kiyi_profiles where user_id=t and searchable and deleted_at is null) or not kiyi_private.account_active(t) or kiyi_private.blocked(u,t)) then raise exception 'Profil bulunamadı.' using errcode='42501';end if;
  return jsonb_build_object('photos',coalesce((select jsonb_agg(s.path order by s.n) from public.kiyi_profiles p cross join lateral jsonb_array_elements_text(case when jsonb_typeof(p.profile->'photos')='array' then p.profile->'photos' else case when coalesce(p.profile->>'avatar','')<>'' then jsonb_build_array(p.profile->>'avatar') else '[]'::jsonb end end)with ordinality s(path,n) where p.user_id=t and not exists(select 1 from kiyi_private.ops_media where path=s.path and hidden)),'[]'));
 elsif action='profile_photo_cleanup' then
  arr=payload->'photos';if jsonb_typeof(arr) is distinct from 'array' or jsonb_array_length(arr)>3 then raise exception 'Geçersiz fotoğraf listesi.';end if;
  return jsonb_build_object('photos',coalesce((select jsonb_agg(s) from jsonb_array_elements_text(arr)s where split_part(s,'/',1)=u::text and not exists(select 1 from public.kiyi_profiles p where p.profile->>'avatar'=s or p.profile->>'photo'=s or coalesce(p.profile->'photos','[]'::jsonb)?s) and not exists(select 1 from public.kiyi_posts where media=s)),'[]'));
 elsif action='profile_photos_update' then
  arr=payload->'photos';
  if jsonb_typeof(arr) is distinct from 'array' then raise exception 'En fazla üç profil fotoğrafı seç.';end if;
  if jsonb_array_length(arr)>3 or exists(select 1 from jsonb_array_elements(arr)s where jsonb_typeof(s)<>'string') or (select count(distinct s) from jsonb_array_elements_text(arr)s)<>jsonb_array_length(arr) then raise exception 'En fazla üç farklı profil fotoğrafı seç.';end if;
  if exists(select 1 from jsonb_array_elements_text(arr)s where length(s)>150 or split_part(s,'/',1)<>u::text or not exists(select 1 from storage.objects o where o.bucket_id='kiyi-media' and o.name=s and coalesce(o.metadata->>'mimetype','') in ('image/jpeg','image/png','image/webp'))) then raise exception 'Fotoğraf sana ait değil veya dosya türü desteklenmiyor.' using errcode='42501';end if;
  update public.kiyi_profiles set profile=profile||jsonb_build_object('photos',arr,'avatar',coalesce(arr->>0,'')) where user_id=u;
  return jsonb_build_object('ok',true);
 elsif action='profile' then
  input_profile=coalesce(payload->'profile','{}');pref='{}';
  if input_profile?'photos' then raise exception 'Fotoğrafları profil fotoğrafı ekranından düzenle.';end if;
  if input_profile?'avatar' and exists(select 1 from public.kiyi_profiles where user_id=u and profile?'photos') and input_profile->>'avatar' is distinct from (select profile->>'avatar' from public.kiyi_profiles where user_id=u) then raise exception 'Fotoğrafları profil fotoğrafı ekranından düzenle.';end if;
  if input_profile?'plate' and exists(select 1 from public.kiyi_verifications where user_id=u and status='approved') and regexp_replace(upper(input_profile->>'plate'),'\s','','g') is distinct from (select plate_key from public.kiyi_profiles where user_id=u) then raise exception 'Doğrulanmış plakan için değişiklik talebi gönder.';end if;
  if input_profile?'plate' and length(coalesce(input_profile->>'plate',''))>30 then raise exception 'Plakanı kontrol et.';end if;
  foreach v in array array['name','ownerName','plate','car','year','color','area','bio','instagram','tiktok','status','avatar','photo'] loop
   if input_profile?v then
    if v in ('avatar','photo') and coalesce(input_profile->>v,'')<>'' and not exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=input_profile->>v and split_part(name,'/',1)=u::text) then raise exception 'Fotoğraf sana ait değil.';end if;
    pref=pref||jsonb_build_object(v,left(coalesce(input_profile->>v,''),case when v in ('avatar','photo') then 150 else 500 end));
   end if;
  end loop;
  update public.kiyi_profiles set profile=public.kiyi_profiles.profile||pref,username=coalesce(nullif(payload->>'username',''),username),searchable=coalesce((payload->>'searchable')::boolean,searchable) where user_id=u;
  return kiyi_private.person(u);
 elsif action='directory' then
  return jsonb_build_object('profiles',coalesce((select jsonb_agg(kiyi_private.person(p.user_id)) from (select * from public.kiyi_profiles where user_id<>u and searchable and kiyi_private.account_active(user_id) and not kiyi_private.blocked(user_id,u) and (not(payload?'plate') or regexp_replace(upper(profile->>'plate'),'\s','','g')=regexp_replace(upper(payload->>'plate'),'\s','','g')) order by created_at desc limit 100)p),'[]'));
 elsif action in ('follow','favorite','block','approve') then
  if t=u or not exists(select 1 from public.kiyi_profiles where user_id=t) then raise exception 'Kullanıcı bulunamadı.';end if;
  if action='block' then
   if coalesce((payload->>'enabled')::boolean,true) then insert into public.kiyi_blocks values(u,t) on conflict do nothing;delete from public.kiyi_follows where (follower=u and target=t)or(follower=t and target=u);delete from public.kiyi_favorites where(owner=u and target=t)or(owner=t and target=u);update public.kiyi_privacy set approved=array_remove(approved,t) where user_id=u;update public.kiyi_privacy set approved=array_remove(approved,u) where user_id=t;
   else delete from public.kiyi_blocks where owner=u and target=t;end if;
  elsif kiyi_private.blocked(u,t) then raise exception 'Bu işlem yapılamaz.';
  elsif action='follow' then if (payload->>'enabled')::boolean then insert into public.kiyi_follows(follower,target) values(u,t) on conflict do nothing;else delete from public.kiyi_follows where follower=u and target=t;end if;
  elsif action='favorite' then if (payload->>'enabled')::boolean then insert into public.kiyi_favorites values(u,t) on conflict do nothing;else delete from public.kiyi_favorites where owner=u and target=t;end if;
  else update public.kiyi_privacy set approved=case when (payload->>'enabled')::boolean then array_append(array_remove(approved,t),t) else array_remove(approved,t) end where user_id=u;end if;
  return jsonb_build_object('ok',true);
 elsif action='remove_follower' then delete from public.kiyi_follows where follower=t and target=u;return jsonb_build_object('ok',true);
 elsif action='appearance' then
  item=payload->>'kind';prod=payload->>'value';cost=0;
  if item='plate' then
   if prod is null or prod not in ('classic','diamond','kiss','named','carbon','chrome') then raise exception 'Geçersiz plaka.';end if;
   if prod in ('kiss','named','carbon','chrome') and length(trim(coalesce(payload->>'name',''))) not between 1 and 20 then raise exception 'Plaka yazısı 1–20 karakter olmalı.';end if;
   if prod<>'classic' then select credits into cost from public.kiyi_products where id='plate' and active;if not found then raise exception 'Plaka özelleştirme kapalı.';end if;end if;
  elsif item='color' then if prod is null or prod !~ '^#[0-9a-f]{6}$' then raise exception 'Geçersiz renk.';end if;if prod not in ('#ffffff','#20242b') then select credits into cost from public.kiyi_products where id='car_color' and active;if not found then raise exception 'Araç rengi özelleştirme kapalı.';end if;end if;
  elsif item='frame' then if prod is null or prod not in ('none','leopard','diamond','blossom','kitty','web','alert','bluekitty','starlight') then raise exception 'Geçersiz çerçeve.';end if;
  else raise exception 'Geçersiz ürün.';end if;
  if cost>0 and not exists(select 1 from public.kiyi_inventory where owner=u and sku=item||':'||prod) then
   rid=(payload->>'request_id')::uuid;if rid is null then raise exception 'İşlem kimliği gerekiyor.';end if;
   if exists(select 1 from public.kiyi_ledger where owner=u and request_id=rid) then raise exception 'Bu işlem kimliği kullanılmış.';end if;
   update public.kiyi_wallets set balance=balance-cost where user_id=u and balance>=cost returning balance into bal;
   if not found then raise exception 'Yeterli jeton yok.';end if;
   insert into public.kiyi_inventory(owner,sku) values(u,item||':'||prod);
   insert into public.kiyi_ledger(owner,request_id,amount,kind,reference) values(u,rid,-cost,'appearance',item||':'||prod);
  end if;
  if item='plate' then update public.kiyi_appearance set plate_style=prod,plate_names=case when prod in ('kiss','named','carbon','chrome') then plate_names||jsonb_build_object(prod,trim(payload->>'name')) else plate_names end where user_id=u;
  elsif item='color' then update public.kiyi_appearance set paint=prod where user_id=u;
  else update public.kiyi_appearance set frame=prod where user_id=u;end if;
  return kiyi_private.person(u);
 elsif action='gift' then
  if t=u or not exists(select 1 from public.kiyi_profiles where user_id=t and searchable and kiyi_private.account_active(t)) or kiyi_private.blocked(u,t) then raise exception 'Alıcıya hediye gönderilemiyor.';end if;
  rid=(payload->>'request_id')::uuid;if rid is null then raise exception 'İşlem kimliği gerekiyor.';end if;
  select to_jsonb(g) into existing from public.kiyi_gifts g where id=rid and sender=u;if found then if existing->>'recipient' is distinct from t::text or existing->>'product' is distinct from payload->>'product' or existing->'song' is distinct from (case when payload->>'product'='song' then payload->'song' else 'null'::jsonb end) then raise exception 'Bu işlem kimliği başka bir hediye için kullanılmış.';end if;return existing;end if;
  if coalesce((select value='false'::jsonb from kiyi_private.ops_settings where key='gifts_enabled'),false) then raise exception 'Hediye gönderimi kısa süreli kapalı.';end if;
  prod=payload->>'product';if prod='song' and coalesce((select value='false'::jsonb from kiyi_private.ops_settings where key='songs_enabled'),false) then raise exception 'Şarkı gönderimi kısa süreli kapalı.';end if;select credits into cost from public.kiyi_products where id=prod and kind in ('gift','song') and active;if not found then raise exception 'Geçersiz hediye.';end if;
  if prod='song' then
   if length(coalesce(payload->'song'->>'title','')) not between 1 and 150 or length(coalesce(payload->'song'->>'artist','')) not between 1 and 150 or coalesce(payload->'song'->>'url','') !~ '^https://(open\.spotify\.com/track/|music\.apple\.com/|itunes\.apple\.com/)' then raise exception 'Geçerli bir şarkı seç.';end if;
   if octet_length((payload->'song')::text)>3000 then raise exception 'Şarkı verisi çok büyük.';end if;
  end if;
  update public.kiyi_wallets set balance=balance-cost where user_id=u and balance>=cost returning balance into bal;if not found then raise exception 'Yeterli jeton yok.';end if;
  insert into public.kiyi_gifts values(rid,u,t,prod,cost,case when prod='song' then payload->'song' else null end,ms);
  insert into public.kiyi_ledger(owner,request_id,amount,kind,reference) values(u,rid,-cost,'gift',rid::text);
  insert into public.kiyi_notifications(recipient,sender,kind,gift_id,created) values(t,u,'gift',rid,ms);
  return (select to_jsonb(g) from public.kiyi_gifts g where id=rid);
 elsif action='read' then update public.kiyi_notifications set read_at=now() where recipient=u and id=(payload->>'id')::uuid;return jsonb_build_object('ok',true);
 elsif action='visit' then
  if t<>u and exists(select 1 from public.kiyi_profiles where user_id=t and searchable) and not kiyi_private.blocked(u,t) then insert into public.kiyi_visits values(t,u,ms) on conflict(owner,visitor) do update set visited=excluded.visited;end if;return jsonb_build_object('ok',true);
 elsif action='visits' then return jsonb_build_object('visitors',coalesce((select jsonb_agg(jsonb_build_object('id',visitor,'visited',visited,'profile',kiyi_private.person(visitor))) from (select * from public.kiyi_visits where owner=u and not kiyi_private.blocked(u,visitor) order by visited desc limit 100)v),'[]'));
 elsif action='report' then
  if t=u or not exists(select 1 from public.kiyi_profiles where user_id=t) then raise exception 'Kullanıcı bulunamadı.';end if;
  if (select count(*) from public.kiyi_reports where reporter=u and created_at>now()-interval '1 hour')>=10 then raise exception 'Şikâyet sınırına ulaştın.';end if;
  insert into public.kiyi_reports(reporter,target,reason,details) values(u,t,payload->>'reason',coalesce(payload->>'details',''));return jsonb_build_object('ok',true);
 elsif action='verification' then
  if not coalesce((payload->>'consent')::boolean,false) or nullif(trim(payload->>'plate'),'') is null or not exists(select 1 from public.kiyi_profiles where user_id=u and nullif(trim(profile->>'plate'),'') is not null) or regexp_replace(upper(payload->>'plate'),'\s','','g')<>(select regexp_replace(upper(profile->>'plate'),'\s','','g') from public.kiyi_profiles where user_id=u) then raise exception 'Plaka ve onay bilgilerini kontrol et.';end if;
  insert into public.kiyi_verifications(user_id,plate,note) values(u,payload->>'plate',payload->>'note') on conflict(user_id) do update set plate=excluded.plate,note=excluded.note,status='pending',created_at=now();return jsonb_build_object('ok',true);
 elsif action='post_create' then
  if nullif(payload->>'media','') is not null and not exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=payload->>'media' and split_part(name,'/',1)=u::text and metadata->>'mimetype' in ('audio/webm','audio/mp4')) then raise exception 'Gönderilerde fotoğraf ve video paylaşımı kapalı.';end if;
  if length(coalesce(payload->>'text',''))>1000 or (coalesce(payload->>'text','')='' and payload->>'media' is null and nullif(payload->'music','null') is null and nullif(payload->'poll','null') is null) then raise exception 'Bir içerik ekle.';end if;
  if (select count(*) from public.kiyi_posts where author=u and created>ms-60000)>=5 then raise exception 'Biraz sonra yeniden dene.';end if;
  if payload->>'media' is not null and not exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=payload->>'media' and split_part(name,'/',1)=u::text) then raise exception 'Dosya sana ait değil.';end if;
  if payload->'poll' is not null and payload->'poll'<>'null'::jsonb then
   arr=payload->'poll'->'options';if arr is null or jsonb_typeof(arr)<>'array' or jsonb_array_length(arr) not between 2 and 4 or length(trim(coalesce(payload->'poll'->>'question','')))=0 or length(payload->'poll'->>'question')>160 or exists(select 1 from jsonb_array_elements_text(arr)s where length(trim(s)) not between 1 and 80) or (select count(distinct lower(trim(s))) from jsonb_array_elements_text(arr)s)<>jsonb_array_length(arr) then raise exception 'Geçerli anket ekle.';end if;
  end if;
  if nullif(payload->'music','null') is not null and (jsonb_typeof(payload->'music')<>'object' or octet_length((payload->'music')::text)>3000 or length(coalesce(payload->'music'->>'title','')) not between 1 and 150 or length(coalesce(payload->'music'->>'artist','')) not between 1 and 150) then raise exception 'Geçerli bir şarkı seç.';end if;
  insert into public.kiyi_posts(author,text,visibility,media,music,poll,created) values(u,coalesce(payload->>'text',''),case when payload->>'visibility'='followers' then 'followers' else 'public' end,payload->>'media',nullif(payload->'music','null'),nullif(payload->'poll','null'),ms) returning id into postid;return jsonb_build_object('post',kiyi_private.post_json(postid,u));
 elsif action='posts' then
  return jsonb_build_object('posts',coalesce((select jsonb_agg(kiyi_private.post_json(z.id,u)) from (select id from public.kiyi_posts where (not(payload?'author') or author=(payload->>'author')::uuid) and (not(payload?'tag') or text ilike '%#'||replace(payload->>'tag','%','')||'%') and kiyi_private.can_post(id,u) order by created desc limit 50)z),'[]'));
 elsif action in ('post_delete','like','vote','comment') then
  postid=(payload->>'id')::uuid;if not kiyi_private.can_post(postid,u) then raise exception 'Paylaşım bulunamadı.';end if;select * into post_record from public.kiyi_posts where id=postid;
  if action='post_delete' then if post_record.author<>u then raise exception 'Bu paylaşımı silemezsin.';end if;delete from public.kiyi_posts where id=postid;return jsonb_build_object('ok',true);
  elsif action='like' then if (payload->>'like')::boolean then insert into public.kiyi_likes values(postid,u) on conflict do nothing;else delete from public.kiyi_likes where post=postid and person=u;end if;
  elsif action='vote' then if post_record.poll is null or (payload->>'choice')::int not between 0 and jsonb_array_length(post_record.poll->'options')-1 then raise exception 'Geçersiz oy.';end if;insert into public.kiyi_votes values(postid,u,(payload->>'choice')::int) on conflict do nothing;
  else if (select count(*) from public.kiyi_comments where author=u and created>ms-60000)>=20 then raise exception 'Yorum sınırına ulaştın.';end if;insert into public.kiyi_comments(post,author,text,created) values(postid,u,trim(payload->>'text'),ms);end if;
  return jsonb_build_object('post',kiyi_private.post_json(postid,u));
 elsif action='sharing' then
  update public.kiyi_privacy set sharing=coalesce((payload->>'enabled')::boolean,sharing),ghost=coalesce((payload->>'ghost')::boolean,ghost),visibility=coalesce(payload->>'visibility',visibility),consented_at=now() where user_id=u;
  if not (select sharing from public.kiyi_privacy where user_id=u) then delete from public.kiyi_positions where user_id=u;end if;return jsonb_build_object('ok',true);
 elsif action='position' then
  if not (select sharing from public.kiyi_privacy where user_id=u) then raise exception 'Konum paylaşımı kapalı.';end if;
  la=(payload->>'lat')::double precision;lo=(payload->>'lng')::double precision;
  if la is null or lo is null or la not between -90 and 90 or lo not between -180 and 180 or coalesce((payload->>'accuracy')::double precision,9999) not between 0 and 200 or coalesce((payload->>'observed_at')::bigint,0) not between ms-120000 and ms+30000 then raise exception 'Geçersiz konum.';end if;
  if exists(select 1 from public.kiyi_positions where user_id=u and received_at>now()-interval '4 seconds') then raise exception 'Konum güncelleme sınırına ulaştın.';end if;
  select id into reg from public.kiyi_regions where active and extensions.st_covers(boundary,extensions.st_setsrid(extensions.st_makepoint(lo,la),4326)) order by id limit 1;
  if reg is null then delete from public.kiyi_positions where user_id=u;return jsonb_build_object('inside',false);end if;
  insert into public.kiyi_positions(user_id,session_id,seq,lat,lng,accuracy,heading,region) values(u,(payload->>'session')::uuid,(payload->>'seq')::bigint,la,lo,(payload->>'accuracy')::double precision,(payload->>'heading')::double precision,reg)
   on conflict(user_id) do update set session_id=excluded.session_id,seq=excluded.seq,lat=excluded.lat,lng=excluded.lng,accuracy=excluded.accuracy,heading=excluded.heading,region=excluded.region,received_at=now() where public.kiyi_positions.session_id<>excluded.session_id or excluded.seq>public.kiyi_positions.seq;
  insert into kiyi_private.ops_metrics(day,region,samples) values((now() at time zone 'Europe/Istanbul')::date,reg,1)on conflict(day,region)do update set samples=kiyi_private.ops_metrics.samples+1;
  return jsonb_build_object('inside',true,'region',reg);
 elsif action='map' then
  return kiyi_private.viewport_map(u,payload);
 elsif action='preferences' then
  pref=coalesce(payload->'preferences','{}');if octet_length(pref::text)>10000 then raise exception 'Tercihler çok büyük.';end if;
  insert into public.kiyi_preferences values(u,pref) on conflict(user_id) do update set preferences=excluded.preferences;return jsonb_build_object('ok',true);
 elsif action='bundle' then
  return jsonb_build_object('me',kiyi_private.person(u),'premium',is_premium,'balance',(select balance from public.kiyi_wallets where user_id=u),'inventory',coalesce((select jsonb_agg(sku) from public.kiyi_inventory where owner=u),'[]'),'following',coalesce((select jsonb_agg(target) from public.kiyi_follows where follower=u),'[]'),'followers',coalesce((select jsonb_agg(follower) from public.kiyi_follows where target=u),'[]'),'favorites',coalesce((select jsonb_agg(target) from public.kiyi_favorites where owner=u),'[]'),'blocked',coalesce((select jsonb_agg(target) from public.kiyi_blocks where owner=u),'[]'),'privacy',(select to_jsonb(q) from public.kiyi_privacy q where user_id=u),'preferences',coalesce((select preferences from public.kiyi_preferences where user_id=u),'{}'),'verification',(select to_jsonb(vr) from public.kiyi_verifications vr where user_id=u),
   'gifts',coalesce((select jsonb_agg(to_jsonb(g)||jsonb_build_object('senderProfile',kiyi_private.person(g.sender),'recipientProfile',kiyi_private.person(g.recipient))) from (select * from public.kiyi_gifts where (sender=u or recipient=u) and not kiyi_private.blocked(sender,recipient) order by created desc limit 100)g),'[]'),
   'notifications',coalesce((select jsonb_agg(to_jsonb(n)) from (select * from public.kiyi_notifications where recipient=u and not kiyi_private.blocked(sender,u) order by created desc limit 100)n),'[]'),'ledger',coalesce((select jsonb_agg(to_jsonb(l)) from(select * from public.kiyi_ledger where owner=u order by created_at desc limit 100)l),'[]'));
 else raise exception 'Desteklenmeyen işlem.';end if;
end $function$;
