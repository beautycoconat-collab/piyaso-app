begin;
create table kiyi_private.stage7_function_backup(name text primary key,definition text not null);
alter table kiyi_private.stage7_function_backup enable row level security;
revoke all on kiyi_private.stage7_function_backup from public,anon,authenticated;
insert into kiyi_private.stage7_function_backup select p.proname,pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='kiyi_private' and p.proname in ('command','command_stage2','command_stage3','command_stage4','command_stage5','command_pre_garage','media_allowed');
create function kiyi_private.session_live(viewer uuid) returns boolean language sql stable security definer set search_path='' as $$
 select viewer is not null and viewer=auth.uid() and (
 -- Owner-run transaction fixtures are not externally usable Auth tokens.
 (session_user='postgres' and coalesce(auth.jwt()->>'role','')='')
 or exists(select 1 from auth.sessions s where s.id=nullif(auth.jwt()->>'session_id','')::uuid and s.user_id=viewer and (s.not_after is null or s.not_after>now())))
$$;
revoke all on function kiyi_private.session_live(uuid) from public,anon,authenticated;
CREATE OR REPLACE FUNCTION kiyi_private.command_pre_garage(action text, payload jsonb)
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
 if action='__stage7_guard' then return jsonb_build_object('ok',true);end if;
 if payload?'target' then t=(payload->>'target')::uuid;end if;
 if action='vehicle_model' then
  prod=payload->>'model';
  if prod is null or not exists(select 1 from public.kiyi_vehicle_models m where m.id=prod and m.kind='car' and m.ready) then raise exception 'Geçersiz araç modeli.' using errcode='22023';end if;
  if t is not null and t<>u then raise exception 'Yalnızca kendi aracını düzenleyebilirsin.' using errcode='42501';end if;
  update public.kiyi_appearance set vehicle_model=prod where user_id=u;
  update public.kiyi_profiles set profile=profile||jsonb_build_object('car',(select name from public.kiyi_vehicle_models where id=prod)) where user_id=u;
  return jsonb_build_object('ok',true,'vehicleModel',prod);
 elsif action='profile_photos' then
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
  if nullif(payload->>'media','') is not null and not exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=payload->>'media' and split_part(name,'/',1)=u::text and (metadata->>'mimetype' in ('audio/webm','audio/mp4') or exists(select 1 from kiyi_private.media_registry r where r.path=payload->>'media' and r.owner=u and r.state='ready'))) then raise exception 'Gönderilerde fotoğraf ve video paylaşımı kapalı.';end if;
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
  elsif action='like' then if (payload->>'like')::boolean then insert into public.kiyi_likes values(postid,u) on conflict do nothing;else delete from public.kiyi_likes l where l.post=postid and l.person=u;end if;
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
end $function$
;
CREATE OR REPLACE FUNCTION kiyi_private.command_stage2(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_variable
declare u uuid=auth.uid();v public.kiyi_vehicles;m public.kiyi_vehicle_models;a jsonb;out jsonb;saved public.kiyi_appearance;vid uuid;
begin
 -- Existing dispatcher bootstraps accounts and enforces suspension/maintenance/deletion.
 perform kiyi_private.command_pre_garage('__stage7_guard','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if not exists(select 1 from public.kiyi_vehicles where owner=u) then
 insert into public.kiyi_vehicles(owner,kind,plate,is_primary,model_id) select u,'car',p.profile->>'plate',true,a.vehicle_model from public.kiyi_profiles p join public.kiyi_appearance a using(user_id) where p.user_id=u returning id into vid;
 insert into public.kiyi_vehicle_customizations(vehicle_id,appearance) select vid,jsonb_build_object('paint',paint,'plateStyle',plate_style,'plateNames',plate_names) from public.kiyi_appearance where user_id=u;
 end if;
 if action='garage_list' then return jsonb_build_object('vehicles',coalesce((select jsonb_agg(to_jsonb(t) order by t.created_at) from(select g.*,c.appearance,c.version,cat.ready,cat.name from public.kiyi_vehicles g join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id left join public.kiyi_vehicle_models cat on cat.id=g.model_id where g.owner=u)t),'[]'),'models',(select jsonb_agg(to_jsonb(cat) order by name) from public.kiyi_vehicle_models cat));
 elsif action='vehicle_create' then
 select * into m from public.kiyi_vehicle_models where id=payload->>'model';if not found then raise exception 'Geçersiz model.' using errcode='22023';end if;
 if length(trim(coalesce(payload->>'plate',''))) not between 1 and 30 then raise exception 'Plakanı kontrol et.';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if exists(select 1 from public.kiyi_profiles where plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g')) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 insert into public.kiyi_vehicles(owner,kind,model_id,plate) values(u,m.kind,m.id,payload->>'plate') returning * into v;
 insert into public.kiyi_vehicle_customizations(vehicle_id) values(v.id);return to_jsonb(v);
 elsif action in ('vehicle_customize','vehicle_model','appearance') and (action<>'appearance' or payload->>'kind'<>'frame') then
 select * into v from public.kiyi_vehicles where owner=u and (case when payload?'vehicle_id' then id=(payload->>'vehicle_id')::uuid else is_primary end) for update;
 if not found or (payload?'target' and (payload->>'target')::uuid<>u) then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 select * into m from public.kiyi_vehicle_models where id=coalesce(payload->>'model',v.model_id);
 if not (action='appearance' and v.kind='car' and v.model_id is null) and (m.id is null or not m.ready or m.kind<>v.kind) then raise exception 'Model katmanları henüz hazır değil.' using errcode='22023';end if;
 if action='vehicle_model' then
 update public.kiyi_vehicles set model_id=m.id where id=v.id;
 if v.is_primary then perform kiyi_private.command_pre_garage(action,payload);end if;
 return jsonb_build_object('ok',true,'vehicleModel',m.id,'vehicle_id',v.id);
 elsif action='appearance' then
 select * into saved from public.kiyi_appearance where user_id=u;
 select appearance into a from public.kiyi_vehicle_customizations where vehicle_id=v.id;
 update public.kiyi_appearance set paint=coalesce(a->>'paint','#ffffff'),plate_style=coalesce(a->>'plateStyle','classic'),plate_names=coalesce(a->'plateNames','{}') where user_id=u;
 out=kiyi_private.command_pre_garage(action,payload);
 update public.kiyi_vehicle_customizations c set appearance=c.appearance||jsonb_build_object('paint',s.paint,'plateStyle',s.plate_style,'plateNames',s.plate_names),version=version+1,updated_at=now() from public.kiyi_appearance s where c.vehicle_id=v.id and s.user_id=u;
 if not v.is_primary then update public.kiyi_appearance set paint=saved.paint,plate_style=saved.plate_style,plate_names=saved.plate_names where user_id=u;end if;
 return jsonb_build_object('ok',true,'vehicle_id',v.id);
 else
 a=payload->'appearance';
 if jsonb_typeof(a) is distinct from 'object' or exists(select 1 from jsonb_object_keys(a) k where k not in ('wrap','rim','accessories')) or octet_length(a::text)>4000 then raise exception 'Geçersiz özelleştirme.';end if;
 -- Choices must exist in the server-maintained compatibility catalog, never arbitrary client JSON.
 if exists(select 1 from jsonb_each(a) e where e.key<>'accessories' and not exists(select 1 from public.kiyi_vehicle_parts p where p.model_id=m.id and p.slot=e.key and p.value=e.value)) or (a?'accessories' and jsonb_typeof(a->'accessories') is distinct from 'object') then raise exception 'Bu parça modelle uyumlu değil.';end if;
 if a?'accessories' then
 if exists(select 1 from jsonb_each(a->'accessories') e where (e.key='text' and (jsonb_typeof(e.value)<>'string' or length(e.value#>>'{}')>12)) or (e.key<>'text' and not exists(select 1 from public.kiyi_vehicle_parts p where p.model_id=m.id and p.slot=e.key and p.value=e.value))) then raise exception 'Geçersiz aksesuar.';end if;
 end if;
 if (payload->>'version')::int is distinct from (select version from public.kiyi_vehicle_customizations where vehicle_id=v.id) then raise exception 'Araç güncellendi; yeniden yükle.' using errcode='PT409';end if;
 update public.kiyi_vehicle_customizations set appearance=appearance||a,version=version+1,updated_at=now() where vehicle_id=v.id;return jsonb_build_object('ok',true);
 end if;
 end if;
 if action='profile' then
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if payload->'profile'?'plate' and exists(select 1 from public.kiyi_vehicles where plate_key=regexp_replace(upper(payload->'profile'->>'plate'),'[[:space:]]','','g') and not(owner=u and is_primary)) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 end if;
 out=kiyi_private.command_pre_garage(action,payload);
 if action='profile' then update public.kiyi_vehicles g set plate=p.profile->>'plate' from public.kiyi_profiles p where g.owner=u and g.is_primary and p.user_id=u;end if;
 return out;
end$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.command_stage3(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_variable
declare u uuid=auth.uid();t uuid;v public.kiyi_vehicles;m public.kiyi_vehicle_models;r jsonb;a jsonb;e record;p public.kiyi_vehicle_part_products;cost int=0;rid uuid;ref text;version int;initial_color text;nextid uuid;
begin
 perform kiyi_private.command_stage2('__stage7_guard','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if payload?'vehicle_id' and not exists(select 1 from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null) then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 if action='directory' and payload?'plate' then
 r=kiyi_private.command_stage2('directory',payload);
 for e in select g.* from public.kiyi_vehicles g where g.plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g') and g.deleted_at is null and g.visibility='public' and g.owner<>u loop
 a=kiyi_private.command('garage_public',jsonb_build_object('target',e.owner));
 if exists(select 1 from jsonb_array_elements(a->'vehicles') z where z->>'id'=e.id::text) and not exists(select 1 from jsonb_array_elements(r->'profiles') z where z->>'id'=e.owner::text) then
 r=jsonb_set(r,'{profiles}',(r->'profiles')||jsonb_build_array(kiyi_private.person(e.owner)||jsonb_build_object('plate',e.plate,'vehicleKind',e.kind,'matchedVehicle',e.id)));
 end if;
 end loop;return r;
 elsif action in ('garage_list','garage_public') then
 t=case when action='garage_public' then (payload->>'target')::uuid else u end;
 if t is null or (t<>u and (not kiyi_private.account_active(t) or kiyi_private.blocked(u,t) or not exists(select 1 from public.kiyi_profiles where user_id=t and searchable and deleted_at is null) or (exists(select 1 from public.kiyi_privacy where user_id=t and ghost) and not kiyi_private.premium(u)) or (exists(select 1 from public.kiyi_positions pos join public.kiyi_regions reg on reg.id=pos.region where pos.user_id=t and reg.premium) and not kiyi_private.premium(u) and not exists(select 1 from public.kiyi_entitlements where user_id=t and featured)))) then return jsonb_build_object('vehicles','[]'::jsonb,'count',0);end if;
 select coalesce(jsonb_agg(to_jsonb(q) order by q.created_at),'[]') into r from(select g.id,g.model_id,g.kind,g.plate,g.is_primary,g.visibility,g.created_at,c.appearance,c.version,cat.name,cat.ready from public.kiyi_vehicles g join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id left join public.kiyi_vehicle_models cat on cat.id=g.model_id where g.owner=t and g.deleted_at is null and (t=u or g.visibility='public') and (g.model_id is not null or nullif(g.plate,'') is not null))q;
 return jsonb_build_object('vehicles',r,'count',jsonb_array_length(r),'models',case when t=u then(select jsonb_agg(to_jsonb(cat) order by name) from public.kiyi_vehicle_models cat) else '[]'::jsonb end,'products',case when t=u then(select coalesce(jsonb_agg(to_jsonb(pp)),'[]') from public.kiyi_vehicle_part_products pp) else '[]'::jsonb end);
 elsif action='vehicle_create' then
 initial_color=coalesce(payload->>'paint','#ffffff');if initial_color !~ '^#[0-9a-f]{6}$' then raise exception 'Geçersiz renk.';end if;
 r=kiyi_private.command_stage2(action,payload);
 update public.kiyi_vehicle_customizations set appearance=appearance||jsonb_build_object('paint',initial_color,'factoryPaint',initial_color) where vehicle_id=(r->>'id')::uuid;
 if not exists(select 1 from public.kiyi_vehicles where owner=u and is_primary and deleted_at is null and nullif(plate,'') is not null) then
 perform kiyi_private.command('vehicle_primary',jsonb_build_object('vehicle_id',r->>'id'));
 end if;
 return r;
 elsif action in ('vehicle_update','vehicle_delete','vehicle_primary') then
 select * into v from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null for update;
 if not found then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 if action='vehicle_delete' then
 if v.is_primary and exists(select 1 from public.kiyi_verifications where user_id=u and status='approved') then raise exception 'Doğrulanmış plakan için değişiklik talebi gönder.';end if;
 update public.kiyi_vehicles set deleted_at=now(),is_primary=false where id=v.id;
 if v.is_primary then
 select id into nextid from public.kiyi_vehicles where owner=u and deleted_at is null and id<>v.id and nullif(plate,'') is not null order by created_at limit 1;
 if nextid is not null then perform kiyi_private.command('vehicle_primary',jsonb_build_object('vehicle_id',nextid));
 else update public.kiyi_profiles set profile=profile||'{"plate":"","car":""}'::jsonb where user_id=u;update public.kiyi_appearance set vehicle_model=null where user_id=u;end if;
 end if;
 return jsonb_build_object('ok',true);
 elsif action='vehicle_primary' then
 if exists(select 1 from public.kiyi_verifications where user_id=u and status='approved' and plate is distinct from v.plate) then raise exception 'Doğrulanmış plakan için değişiklik talebi gönder.';end if;
 update public.kiyi_vehicles set is_primary=false where owner=u;
 update public.kiyi_vehicles set is_primary=true where id=v.id;
 select appearance into a from public.kiyi_vehicle_customizations where vehicle_id=v.id;
 update public.kiyi_appearance set vehicle_model=v.model_id,paint=coalesce(a->>'paint','#ffffff'),plate_style=coalesce(a->>'plateStyle','classic'),plate_names=coalesce(a->'plateNames','{}') where user_id=u;
 update public.kiyi_profiles set profile=profile||jsonb_build_object('plate',v.plate,'car',(select name from public.kiyi_vehicle_models where id=v.model_id)) where user_id=u;
 return jsonb_build_object('ok',true);
 else
 perform pg_advisory_xact_lock(hashtextextended('kiyi-plate-registry',0));
 if payload?'plate' then
 if length(trim(payload->>'plate')) not between 1 and 30 then raise exception 'Plakanı kontrol et.';end if;
 if v.is_primary then perform kiyi_private.command_stage2('profile',jsonb_build_object('profile',jsonb_build_object('plate',payload->>'plate')));
 else
 if exists(select 1 from public.kiyi_profiles where plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g')) then raise exception 'Plaka kayıtlı.' using errcode='23505';end if;
 update public.kiyi_vehicles set plate=payload->>'plate' where id=v.id;
 end if;end if;
 if payload?'visibility' then update public.kiyi_vehicles set visibility=payload->>'visibility' where id=v.id;end if;
 return jsonb_build_object('ok',true);
 end if;
 elsif action='motorcycle_customize' then
 select * into v from public.kiyi_vehicles where id=(payload->>'vehicle_id')::uuid and owner=u and deleted_at is null for update;
 select * into m from public.kiyi_vehicle_models where id=v.model_id and kind='motorcycle' and ready;
 if v.id is null or m.id is null then raise exception 'Motosiklet görseli ve katmanları henüz hazır değil.' using errcode='22023';end if;
 a=payload->'appearance';rid=(payload->>'request_id')::uuid;ref=v.id::text||':'||a::text;
 if rid is null or jsonb_typeof(a) is distinct from 'object' or octet_length(a::text)>4000 then raise exception 'Geçersiz işlem.';end if;
 if exists(select 1 from public.kiyi_ledger where owner=u and request_id=rid) then
 if not exists(select 1 from public.kiyi_ledger where owner=u and request_id=rid and reference=ref and kind='vehicle_parts') then raise exception 'İşlem kimliği daha önce kullanıldı.';end if;
 return jsonb_build_object('ok',true,'replayed',true);end if;
 select c.version into version from public.kiyi_vehicle_customizations c where c.vehicle_id=v.id;
 if version is distinct from (payload->>'version')::int then raise exception 'Araç güncellendi; yeniden yükle.' using errcode='PT409';end if;
 select coalesce(c.appearance->>'factoryPaint',c.appearance->>'paint','#ffffff') into initial_color from public.kiyi_vehicle_customizations c where c.vehicle_id=v.id;
 for e in select * from jsonb_each(a) loop
 if e.key='paint' and e.value=to_jsonb(initial_color) then continue;end if;
 select * into p from public.kiyi_vehicle_part_products where model_id=m.id and slot=e.key and value=e.value;
 if not found then raise exception 'Modelle uyumsuz parça.' using errcode='22023';end if;
 if not exists(select 1 from public.kiyi_inventory where owner=u and sku=p.sku) then cost=cost+p.credits;end if;
 end loop;
 update public.kiyi_wallets set balance=balance-cost where user_id=u and balance>=cost;
 if not found then raise exception 'Yeterli kredi yok.';end if;
 for e in select * from jsonb_each(a) loop
 insert into public.kiyi_inventory(owner,sku) select u,sku from public.kiyi_vehicle_part_products where model_id=m.id and slot=e.key and value=e.value on conflict do nothing;
 end loop;
 insert into public.kiyi_ledger(owner,request_id,amount,kind,reference) values(u,rid,-cost,'vehicle_parts',ref);
 update public.kiyi_vehicle_customizations set appearance=appearance||a,version=version+1,updated_at=now() where vehicle_id=v.id;
 if v.is_primary and a?'paint' then update public.kiyi_appearance set paint=a->>'paint' where user_id=u;end if;
 return jsonb_build_object('ok',true,'charged',cost);
 end if;
 return kiyi_private.command_stage2(action,payload);
end$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.command_stage4(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_variable
declare u uuid=auth.uid();p public.kiyi_posts;r jsonb;vid uuid;media text;txt text;loc text;visibility text;rid uuid;ids uuid[];pid uuid;n int;category text;result jsonb='[]';next_cursor jsonb;vehicle jsonb;
begin
 perform kiyi_private.command_stage3('__stage7_guard','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if action='posts' then
 category=coalesce(payload->>'filter','all');n=least(30,greatest(1,coalesce((payload->>'limit')::int,20)));
 if category not in ('all','following','photo','video','car','motorcycle') then raise exception 'Geçersiz filtre.' using errcode='22023';end if;
 select array_agg(q.id order by q.created desc,q.id desc) into ids from(
 select s.id,s.created from public.kiyi_posts s
 where kiyi_private.can_post(s.id,u)
 and (not(payload?'author') or s.author=(payload->>'author')::uuid)
 and (not(payload?'tag') or s.text ilike '%#'||replace(payload->>'tag','%','')||'%')
 and (not(payload?'cursor') or payload->'cursor'='null'::jsonb or (s.created,s.id)<((payload->'cursor'->>'created')::bigint,(payload->'cursor'->>'id')::uuid))
 and (category='all' or (category='following' and exists(select 1 from public.kiyi_follows where follower=u and target=s.author))
 or (category='photo' and exists(select 1 from storage.objects o where o.bucket_id='kiyi-media' and o.name=s.media and o.metadata->>'mimetype' like 'image/%'))
 or (category='video' and exists(select 1 from storage.objects o where o.bucket_id='kiyi-media' and o.name=s.media and o.metadata->>'mimetype' like 'video/%'))
 or (category in ('car','motorcycle') and kiyi_private.social_vehicle(s.vehicle_id,u)->>'kind'=category))
 order by s.created desc,s.id desc limit n+1)q;
 if ids is not null then
 foreach pid in array ids[1:n] loop result=result||jsonb_build_array(kiyi_private.post_json(pid,u));end loop;
 if cardinality(ids)>n then select jsonb_build_object('created',s.created,'id',s.id) into next_cursor from public.kiyi_posts s where s.id=ids[n];end if;
 end if;
 return jsonb_build_object('posts',result,'next',next_cursor);
 elsif action in ('post_create','post_edit') then
 if action='post_edit' then
 select * into p from public.kiyi_posts where id=(payload->>'id')::uuid and author=u and not hidden for update;
 if not found then raise exception 'Gönderiyi düzenleyemezsin.' using errcode='42501';end if;
 if (payload->>'version')::int is distinct from p.version then raise exception 'Gönderi değişmiş; yeniden yükle.' using errcode='PT409';end if;
 end if;
 txt=case when payload?'text' then coalesce(payload->>'text','') else coalesce(p.text,'') end;
 media=case when payload?'media' then nullif(payload->>'media','') else p.media end;
 vid=case when payload?'vehicle_id' then nullif(payload->>'vehicle_id','')::uuid else p.vehicle_id end;
 loc=case when payload?'location' then nullif(payload->>'location','') else p.location_label end;
 visibility=coalesce(payload->>'visibility',p.visibility,'public');
 if length(txt)>1000 or visibility not in ('public','followers') then raise exception 'Gönderi bilgilerini kontrol et.';end if;
 if loc is not null and loc not in ('Antalya','Konyaaltı','Lara','Kültür','Bozkan','İzmir','Alsancak','Küçükpark','Bornova') then raise exception 'Genel konum etiketini kontrol et.';end if;
 if nullif(trim(txt),'') is null and media is null and coalesce(nullif(payload->'music','null'),p.music) is null and coalesce(nullif(payload->'poll','null'),p.poll) is null then raise exception 'Boş gönderi paylaşılamaz.';end if;
 if vid is not null and not exists(select 1 from public.kiyi_vehicles where id=vid and owner=u and deleted_at is null) then raise exception 'Yalnızca garajındaki aracı etiketleyebilirsin.' using errcode='42501';end if;
 if media is not null and not exists(select 1 from storage.objects o where o.bucket_id='kiyi-media' and o.name=media and split_part(o.name,'/',1)=u::text and (o.metadata->>'mimetype' in ('audio/webm','audio/mp4') or exists(select 1 from kiyi_private.media_registry mr where mr.path=o.name and mr.owner=u and mr.state='ready'))) then raise exception 'Medya hazır değil veya sana ait değil.' using errcode='42501';end if;
 if action='post_create' then
 rid=(payload->>'request_id')::uuid;
 if rid is not null then
 select * into p from public.kiyi_posts where author=u and request_id=rid;
 if found then
 if p.text is distinct from txt or p.media is distinct from media or p.vehicle_id is distinct from vid or p.location_label is distinct from loc or p.visibility<>visibility then raise exception 'Bu işlem kimliği başka gönderide kullanıldı.';end if;
 return jsonb_build_object('post',kiyi_private.post_json(p.id,u),'replayed',true);
 end if;end if;
 r=kiyi_private.command_stage3(action,payload||jsonb_build_object('text',txt,'media',media,'visibility',visibility));pid=(r->'post'->>'id')::uuid;
 update public.kiyi_posts set vehicle_id=vid,location_label=loc,request_id=rid where id=pid;
 else
 pid=p.id;
 update public.kiyi_posts set text=txt,media=media,vehicle_id=vid,location_label=loc,visibility=visibility,version=version+1,updated_at=now() where id=pid;
 end if;
 return jsonb_build_object('post',kiyi_private.post_json(pid,u));
 elsif action='post_get' then
 r=kiyi_private.post_json((payload->>'id')::uuid,u);if r is null then raise exception 'Gönderi bulunamadı.' using errcode='42501';end if;return jsonb_build_object('post',r);
 elsif action='post_delete' then
 delete from public.kiyi_posts where id=(payload->>'id')::uuid and author=u returning * into p;
 if not found then raise exception 'Bu gönderiyi silemezsin.';end if;return jsonb_build_object('ok',true);
 elsif action='post_report' then
 select * into p from public.kiyi_posts where id=(payload->>'id')::uuid and kiyi_private.can_post(id,u);
 if not found then raise exception 'Gönderi bulunamadı.' using errcode='42501';end if;
 return kiyi_private.command_stage3('report',jsonb_build_object('target',p.author,'reason',coalesce(payload->>'reason','Uygunsuz içerik'),'details',left('[post:'||p.id::text||'] '||coalesce(payload->>'details',''),500)));
 elsif action='post_vehicle' then
 select * into p from public.kiyi_posts where id=(payload->>'id')::uuid and kiyi_private.can_post(id,u);
 if not found then raise exception 'Gönderi bulunamadı.' using errcode='42501';end if;
 vehicle=kiyi_private.social_vehicle(p.vehicle_id,u);if vehicle is null then raise exception 'Araç bilgileri kapalı.' using errcode='42501';end if;
 return jsonb_build_object('vehicle',vehicle);
 end if;
 return kiyi_private.command_stage3(action,payload);
end$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.command_stage5(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_variable
declare u uuid=auth.uid();pid uuid;cid uuid;rid uuid;vid uuid;v public.kiyi_vehicles;p public.kiyi_posts;c public.kiyi_comments;txt text;r jsonb;z jsonb;results jsonb='[]';ids uuid[];n int;next_cursor jsonb;enabled boolean;ms bigint=(extract(epoch from clock_timestamp())*1000)::bigint;
begin
 perform kiyi_private.command_stage4('__stage7_guard','{}');
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if action='tag_settings' then
 if payload?'enabled' then
 if jsonb_typeof(payload->'enabled')<>'boolean' then raise exception 'Geçersiz izin.';end if;
 perform kiyi_private.social_rate(u,'settings',10);
 update public.kiyi_privacy set allow_plate_tags=(payload->>'enabled')::boolean where user_id=u;
 end if;
 return jsonb_build_object('enabled',(select allow_plate_tags from public.kiyi_privacy where user_id=u));
 elsif action in ('directory','tag_search') and payload?'plate' then
 if action='tag_search' then perform kiyi_private.social_rate(u,'tag_search',30);end if;
 r=kiyi_private.command_stage4('directory',payload);
 for v in select g.* from public.kiyi_vehicles g where g.deleted_at is null and g.plate_key=regexp_replace(upper(payload->>'plate'),'[[:space:]]','','g') and g.owner<>u loop
 if kiyi_private.social_vehicle(v.id,u) is not null and exists(select 1 from jsonb_array_elements(r->'profiles') x where x->>'id'=v.owner::text) then
 if action='directory' then results=results||jsonb_build_array(kiyi_private.social_person(v.owner,u)||jsonb_build_object('plate',v.plate,'matchedVehicle',v.id,'vehicleKind',v.kind));
 elsif coalesce((select allow_plate_tags from public.kiyi_privacy where user_id=v.owner),false) then results=results||jsonb_build_array(kiyi_private.social_vehicle(v.id,u)||jsonb_build_object('profile',kiyi_private.social_person(v.owner,u)));end if;
 end if;end loop;
 return jsonb_build_object(case when action='directory' then 'profiles' else 'vehicles' end,results);
 elsif action in ('post_create','post_edit') then
 if action='post_edit' then select * into p from public.kiyi_posts where id=(payload->>'id')::uuid and author=u for update;if not found then raise exception 'Gönderiyi düzenleyemezsin.' using errcode='42501';end if;end if;
 vid=case when payload?'vehicle_id' then nullif(payload->>'vehicle_id','')::uuid else p.vehicle_id end;
 if vid is not null then
 select * into v from public.kiyi_vehicles where id=vid and deleted_at is null for share;
 if not found then raise exception 'Araç bulunamadı.' using errcode='42501';end if;
 if v.owner<>u then
 perform 1 from public.kiyi_privacy where user_id=v.owner and allow_plate_tags for share;
 if not found or kiyi_private.social_vehicle(v.id,u) is null then raise exception 'Bu plaka etiketlemeye açık değil.' using errcode='42501';end if;
 end if;end if;
 -- Existing Stage 4 validates all other fields; attach the validated tag atomically.
 if action='post_create' and payload?'request_id' then
 select * into p from public.kiyi_posts where author=u and request_id=(payload->>'request_id')::uuid;
 if found then
 if p.vehicle_id is distinct from vid then raise exception 'İşlem kimliği başka gönderide kullanıldı.';end if;
 update public.kiyi_posts set vehicle_id=null where id=p.id;
 end if;end if;
 if action='post_edit' then update public.kiyi_posts set vehicle_id=null where id=p.id;end if;
 r=kiyi_private.command_stage4(action,payload-'vehicle_id');pid=(r->'post'->>'id')::uuid;
 update public.kiyi_posts set vehicle_id=vid where id=pid;
 return r||jsonb_build_object('post',kiyi_private.post_json(pid,u));
 elsif action='post_untag' then
 perform kiyi_private.social_rate(u,'manage',60);
 select s.* into p from public.kiyi_posts s join public.kiyi_vehicles g on g.id=s.vehicle_id where s.id=(payload->>'id')::uuid and (s.author=u or g.owner=u) for update of s;
 if not found then raise exception 'Etiketi kaldıramazsın.' using errcode='42501';end if;
 update public.kiyi_posts set vehicle_id=null,version=version+1,updated_at=now() where id=p.id;return jsonb_build_object('ok',true);
 elsif action='tagged_posts' then
 return jsonb_build_object('posts',coalesce((select jsonb_agg(kiyi_private.post_json(q.id,u)) from(select s.id from public.kiyi_posts s join public.kiyi_vehicles g on g.id=s.vehicle_id where g.owner=u and s.author<>u and kiyi_private.can_post(s.id,u) order by s.created desc,s.id desc limit 30)q),'[]'));
 elsif action='like' then
 if jsonb_typeof(payload->'like') is distinct from 'boolean' then raise exception 'Geçersiz beğeni.';end if;
 perform kiyi_private.social_rate(u,'like',60);return kiyi_private.command_stage4(action,payload);
 elsif action='follow' then
 if jsonb_typeof(payload->'enabled') is distinct from 'boolean' then raise exception 'Geçersiz takip.';end if;
 perform kiyi_private.social_rate(u,'follow',30);
 if (payload->>'enabled')::boolean and (not kiyi_private.account_active((payload->>'target')::uuid) or not kiyi_private.social_identity_visible((payload->>'target')::uuid,u)) then raise exception 'Bu hesap görünür değil.' using errcode='42501';end if;
 return kiyi_private.command_stage4(action,payload);
 elsif action in ('comment','comment_edit','comment_delete','comments','comment_profile') then

 return kiyi_private.comment_ops(action,payload);
 end if;
 return kiyi_private.command_stage4(action,payload);
end$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.command(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
#variable_conflict use_variable
declare u uuid=auth.uid();r jsonb;settings jsonb;target_id uuid;pid uuid;cid uuid;subject uuid;report_id uuid;subject_type text;why text;details_text text;note jsonb;k text;
begin
 if not kiyi_private.session_live(u) then raise exception 'Oturum geçersiz. Yeniden giriş yap.' using errcode='42501';end if;
 if action in ('ops_config','support_create','privacy_request','appeal_create','sanctions_mine','cases_mine','plate_change_request') then return kiyi_private.command_pre_garage(action,payload);end if;
 -- Preserve the existing suspension, deletion, maintenance and Auth guard.
 if action='bundle' then r=kiyi_private.command_stage5('bundle','{}');else perform kiyi_private.command_stage5('__stage7_guard','{}');end if;
 if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>20000 then raise exception 'Geçersiz işlem.';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if action='profile_photos' and coalesce(nullif(payload->>'target','')::uuid,u)<>u and kiyi_private.social_person((payload->>'target')::uuid,u) is null then raise exception 'Bu profil görünür değil.' using errcode='42501';end if;
 if action='bundle' then
 perform kiyi_private.sync_badges(u);
 return r||jsonb_build_object('notificationSettings',coalesce((select sp.settings from public.kiyi_social_preferences sp where sp.owner=u),'{}'), 'notifications',coalesce((select jsonb_agg(q.item order by q.created desc,q.id desc) from(select n.id,n.created,kiyi_private.notification_json(n.id,u) item from public.kiyi_notifications n where recipient=u and not kiyi_private.blocked(sender,u) order by created desc,id desc limit 200)q where q.item is not null),'[]'));
 elsif action='badges' then
 target_id=coalesce(nullif(payload->>'target','')::uuid,u);
 if not kiyi_private.account_active(target_id) or kiyi_private.social_person(target_id,u) is null then raise exception 'Bu profil görünür değil.' using errcode='42501';end if;
 -- Only reconcile own achievements; foreign reads never generate notifications.
 if target_id=u then perform kiyi_private.sync_badges(u);end if;
 return jsonb_build_object('badges',coalesce((select jsonb_agg(jsonb_build_object('code',b.code,'earned_at',b.earned_at) order by b.earned_at,b.code) from public.kiyi_badges b where b.owner=target_id and (code<>'verified' or exists(select 1 from public.kiyi_entitlements where user_id=target_id and verified))),'[]'));
 elsif action='notification_settings' then
 if payload?'settings' then
 settings=payload->'settings';
 if jsonb_typeof(settings)<>'object' or exists(select 1 from jsonb_each(settings)e where e.key not in ('follow','like','comment','tag','badge') or jsonb_typeof(e.value)<>'boolean') then raise exception 'Geçersiz bildirim tercihi.';end if;
 perform kiyi_private.social_rate(u,'notification_settings',20);
 insert into public.kiyi_social_preferences(owner,settings) values(u,settings) on conflict(owner) do update set settings=public.kiyi_social_preferences.settings||excluded.settings;
 end if;
 return jsonb_build_object('settings',coalesce((select sp.settings from public.kiyi_social_preferences sp where sp.owner=u),'{}'),'push_available',false);
 elsif action in ('notification_open','read') then
 note=kiyi_private.notification_json((payload->>'id')::uuid,u);if note is null then raise exception 'Bildirim bulunamadı veya artık görünür değil.' using errcode='42501';end if;
 update public.kiyi_notifications set read_at=coalesce(read_at,now()) where id=(payload->>'id')::uuid and recipient=u;
 return jsonb_build_object('ok',true,'notification',note);
 elsif action in ('content_report','post_report') then
 perform kiyi_private.social_rate(u,'report',10);
 if (select count(*) from public.kiyi_reports where reporter=u and created_at>now()-interval '1 hour')>=10 then raise exception 'Saatlik şikâyet sınırına ulaştın.' using errcode='PT429';end if;
 subject_type=case when action='post_report' then 'post' else payload->>'kind' end;subject=(payload->>'id')::uuid;why=trim(payload->>'reason');details_text=trim(coalesce(payload->>'details',''));
 if why='Taciz' then why='Taciz veya hakaret';end if;
 if why is null or why not in ('Spam','Taciz veya hakaret','Uygunsuz içerik','Sahte hesap','Gizlilik ihlali','Diğer') or length(details_text)>450 then raise exception 'Şikâyet bilgilerini kontrol et.';end if;
 if subject_type='post' then select author,id into target_id,pid from public.kiyi_posts where id=subject and kiyi_private.can_post(id,u);
 elsif subject_type='comment' then select author,post,id into target_id,pid,cid from public.kiyi_comments where id=subject and kiyi_private.comment_json(id,u) is not null;
 else raise exception 'Geçersiz içerik türü.';end if;
 if target_id is null or target_id=u then raise exception 'Bu içeriği şikâyet edemezsin.' using errcode='42501';end if;
 select id into report_id from public.kiyi_reports where reporter=u and subject_kind=subject_type and subject_id=subject and status in ('pending','in_review') order by created_at desc limit 1;
 if report_id is null then insert into public.kiyi_reports(reporter,target,reason,details,subject_kind,subject_id) values(u,target_id,why,details_text,subject_type,subject) returning id into report_id;end if;
 return jsonb_build_object('ok',true,'id',report_id,'status',(select status from public.kiyi_reports where id=report_id));
 elsif action='my_reports' then
 return jsonb_build_object('reports',coalesce((select jsonb_agg(to_jsonb(q) order by q.created_at desc) from(select id,subject_kind,subject_id,reason,status,created_at from public.kiyi_reports where reporter=u order by created_at desc,id desc limit 50)q),'[]'));
 end if;
 return kiyi_private.command_stage5(action,payload);
end$function$
;
create or replace function kiyi_private.media_allowed(path text,viewer uuid) returns boolean language sql stable security definer set search_path='' as $$
 select kiyi_private.session_live(viewer) and kiyi_private.account_active(viewer)
 and not exists(select 1 from kiyi_private.ops_media where path=media_allowed.path and hidden)
 and (split_part(path,'/',1)=viewer::text
 or exists(select 1 from public.kiyi_posts p where p.media=path and kiyi_private.can_post(p.id,viewer))
 or exists(select 1 from public.kiyi_profiles p where (p.profile->>'avatar'=path or p.profile->>'photo'=path or coalesce(p.profile->'photos','[]'::jsonb)?path) and kiyi_private.account_active(p.user_id) and (p.user_id=viewer or p.searchable) and kiyi_private.social_identity_visible(p.user_id,viewer)));
$$;
commit;
