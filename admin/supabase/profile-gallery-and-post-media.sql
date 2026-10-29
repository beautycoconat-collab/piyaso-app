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
  return jsonb_build_object('people',coalesce((select jsonb_agg(case when is_premium or (not r.premium and not q.ghost) or (not q.ghost and exists(select 1 from public.kiyi_entitlements where user_id=l.user_id and featured)) or l.user_id=u then kiyi_private.person(l.user_id)||jsonb_build_object('pos',jsonb_build_array(case when l.user_id=u then l.lat else round(l.lat::numeric,3)::double precision end,case when l.user_id=u then l.lng else round(l.lng::numeric,3)::double precision end),'heading',l.heading,'updated',extract(epoch from l.received_at)*1000) else jsonb_build_object('id',gen_random_uuid(),'ghost',true,'username','hayalet','plate','** ***','pos',jsonb_build_array(case when l.user_id=u then l.lat else round(l.lat::numeric,3)::double precision end,case when l.user_id=u then l.lng else round(l.lng::numeric,3)::double precision end),'heading',l.heading,'updated',extract(epoch from l.received_at)*1000) end) from (select * from public.kiyi_positions where received_at>now()-interval '90 seconds' and region=coalesce(payload->>'region','konyaalti') limit 200)l join public.kiyi_regions r on r.id=l.region join public.kiyi_privacy q on q.user_id=l.user_id where q.sharing and r.active and kiyi_private.account_active(l.user_id) and not kiyi_private.blocked(u,l.user_id) and (q.visibility='all' or l.user_id=u or u=any(q.approved))),'[]'));
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
CREATE OR REPLACE FUNCTION kiyi_private.person(u uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
select jsonb_strip_nulls(jsonb_build_object('name',p.profile->'name','ownerName',p.profile->'ownerName','plate',p.profile->'plate','car',p.profile->'car','year',p.profile->'year','color',p.profile->'color','area',p.profile->'area','bio',p.profile->'bio','instagram',p.profile->'instagram','tiktok',p.profile->'tiktok','status',p.profile->'status','avatar',case when jsonb_typeof(p.profile->'photos')='array' then (select to_jsonb(s.path) from jsonb_array_elements_text(p.profile->'photos')with ordinality s(path,n) where not exists(select 1 from kiyi_private.ops_media where path=s.path and hidden) order by s.n limit 1) else case when exists(select 1 from kiyi_private.ops_media where path=p.profile->>'avatar' and hidden) then null else p.profile->'avatar' end end,'photo',case when exists(select 1 from kiyi_private.ops_media where path=p.profile->>'photo' and hidden) then null else p.profile->'photo' end))||jsonb_build_object('id',p.user_id,'username',p.username,'searchable',p.searchable,'verified',coalesce(e.verified,false),'plateStyle',coalesce(a.plate_style,'classic'),'plateNames',coalesce(a.plate_names,'{}'),'paint',coalesce(a.paint,'#ffffff'),'avatarFrame',coalesce(a.frame,'none'),'serverProfile',true,'supabaseProfile',true,'publicProfile',true,'sharing',false,'featured',coalesce(e.featured,false),'featuredRank',coalesce(e.featured_rank,100),'online',exists(select 1 from public.kiyi_positions l where l.user_id=u and l.received_at>now()-interval '90 seconds')) from public.kiyi_profiles p left join public.kiyi_appearance a on a.user_id=p.user_id left join public.kiyi_entitlements e on e.user_id=p.user_id where p.user_id=u and kiyi_private.account_active(u)
$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.media_allowed(path text, viewer uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$select viewer is not null and not exists(select 1 from kiyi_private.ops_media where path=media_allowed.path and hidden) and (split_part(path,'/',1)=viewer::text or exists(select 1 from public.kiyi_posts p where p.media=path and kiyi_private.can_post(p.id,viewer)) or exists(select 1 from public.kiyi_profiles p where (p.profile->>'avatar'=path or p.profile->>'photo'=path or coalesce(p.profile->'photos','[]'::jsonb)?path) and kiyi_private.account_active(p.user_id) and (p.user_id=viewer or p.searchable) and not kiyi_private.blocked(p.user_id,viewer)))$function$
;
CREATE OR REPLACE FUNCTION kiyi_private.admin_media_allowed(path text, deleting boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid();r text;ok boolean;
begin
 if u is null or auth.jwt()->>'aal' is distinct from 'aal2' then return false;end if;
 select role into r from kiyi_private.admin_memberships where user_id=u and active;
 if r not in ('super_admin','admin','moderator') or r is null then return false;end if;
 if not exists(select 1 from auth.sessions where id=(auth.jwt()->>'session_id')::uuid and user_id=u) or not exists(select 1 from kiyi_private.admin_leases where session_id=(auth.jwt()->>'session_id')::uuid and user_id=u and revoked_at is null and last_seen>now()-interval '15 minutes' and expires_at>now())then return false;end if;
 if deleting then ok=r='super_admin' and exists(select 1 from kiyi_private.ops_jobs where kind='storage_erasure' and status='pending' and subject::text=split_part(path,'/',1));
 else ok=exists(select 1 from public.kiyi_posts where media=path) or exists(select 1 from public.kiyi_profiles where profile->>'avatar'=path or profile->>'photo'=path or coalesce(profile->'photos','[]'::jsonb)?path) or exists(select 1 from kiyi_private.ops_jobs where kind='storage_erasure' and status='pending' and subject::text=split_part(path,'/',1));end if;
 if ok then insert into kiyi_private.admin_audit(actor,action,entity_id,session_id)values(u,case when deleting then 'media.delete' else 'media.read' end,path,(auth.jwt()->>'session_id')::uuid);end if;
 return ok;
end $function$
;
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
end $function$
;

