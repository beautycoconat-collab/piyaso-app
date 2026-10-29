CREATE OR REPLACE FUNCTION kiyi_private.command(action text, payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid();t uuid;rid uuid;prod text;cost integer;bal bigint;existing jsonb;item text;input_profile jsonb;person jsonb;arr jsonb;postid uuid;post_record public.kiyi_posts;out jsonb;ms bigint=(extract(epoch from clock_timestamp())*1000)::bigint;is_premium boolean;reg text;la double precision;lo double precision;pref jsonb;names jsonb;v text;
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'Giriş yapmalısın.' using errcode='42501';end if;
 if exists(select 1 from public.kiyi_entitlements where user_id=u and suspended) then raise exception 'Hesabın kullanıma kapalı.' using errcode='42501';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 insert into public.kiyi_profiles(user_id,username) values(u,'kiyi_'||left(replace(u::text,'-',''),24)) on conflict(user_id) do nothing;
 insert into public.kiyi_wallets values(u,0) on conflict do nothing;
 insert into public.kiyi_appearance(user_id) values(u) on conflict do nothing;
 insert into public.kiyi_privacy(user_id) values(u) on conflict do nothing;
 is_premium=kiyi_private.premium(u);
 if payload?'target' then t=(payload->>'target')::uuid;end if;
 if action='profile' then
  input_profile=coalesce(payload->'profile','{}');pref='{}';
  foreach v in array array['name','ownerName','plate','car','year','color','area','bio','instagram','tiktok','status','avatar','photo'] loop
   if input_profile?v then
    if v in ('avatar','photo') and coalesce(input_profile->>v,'')<>'' and not exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=input_profile->>v and split_part(name,'/',1)=u::text) then raise exception 'Fotoğraf sana ait değil.';end if;
    pref=pref||jsonb_build_object(v,left(coalesce(input_profile->>v,''),case when v in ('avatar','photo') then 150 else 500 end));
   end if;
  end loop;
  update public.kiyi_profiles set profile=public.kiyi_profiles.profile||pref,username=coalesce(nullif(payload->>'username',''),username),searchable=coalesce((payload->>'searchable')::boolean,searchable) where user_id=u;
  return kiyi_private.person(u);
 elsif action='directory' then
  return jsonb_build_object('profiles',coalesce((select jsonb_agg(kiyi_private.person(p.user_id)) from (select * from public.kiyi_profiles where user_id<>u and searchable and not kiyi_private.blocked(user_id,u) and (not(payload?'plate') or regexp_replace(upper(profile->>'plate'),'\s','','g')=regexp_replace(upper(payload->>'plate'),'\s','','g')) order by created_at desc limit 100)p),'[]'));
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
   if prod<>'classic' then cost=100;end if;
  elsif item='color' then if prod is null or prod !~ '^#[0-9a-f]{6}$' then raise exception 'Geçersiz renk.';end if;if prod not in ('#ffffff','#20242b') then cost=500;end if;
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
  if t=u or not exists(select 1 from public.kiyi_profiles where user_id=t and searchable) or kiyi_private.blocked(u,t) then raise exception 'Alıcıya hediye gönderilemiyor.';end if;
  rid=(payload->>'request_id')::uuid;if rid is null then raise exception 'İşlem kimliği gerekiyor.';end if;
  select to_jsonb(g) into existing from public.kiyi_gifts g where id=rid and sender=u;if found then return existing;end if;
  prod=payload->>'product';select credits into cost from public.kiyi_products where id=prod and kind in ('gift','song');if not found then raise exception 'Geçersiz hediye.';end if;
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
  select id into reg from public.kiyi_regions where extensions.st_covers(boundary,extensions.st_setsrid(extensions.st_makepoint(lo,la),4326)) order by id limit 1;
  if reg is null then delete from public.kiyi_positions where user_id=u;return jsonb_build_object('inside',false);end if;
  insert into public.kiyi_positions(user_id,session_id,seq,lat,lng,accuracy,heading,region) values(u,(payload->>'session')::uuid,(payload->>'seq')::bigint,la,lo,(payload->>'accuracy')::double precision,(payload->>'heading')::double precision,reg)
   on conflict(user_id) do update set session_id=excluded.session_id,seq=excluded.seq,lat=excluded.lat,lng=excluded.lng,accuracy=excluded.accuracy,heading=excluded.heading,region=excluded.region,received_at=now() where public.kiyi_positions.session_id<>excluded.session_id or excluded.seq>public.kiyi_positions.seq;
  return jsonb_build_object('inside',true,'region',reg);
 elsif action='map' then
  return jsonb_build_object('people',coalesce((select jsonb_agg(case when is_premium or (not r.premium and not q.ghost) or l.user_id=u then kiyi_private.person(l.user_id)||jsonb_build_object('pos',jsonb_build_array(l.lat,l.lng),'heading',l.heading,'updated',extract(epoch from l.received_at)*1000) else jsonb_build_object('id',gen_random_uuid(),'ghost',true,'username','hayalet','plate','** ***','pos',jsonb_build_array(l.lat,l.lng),'heading',l.heading,'updated',extract(epoch from l.received_at)*1000) end) from (select * from public.kiyi_positions where received_at>now()-interval '90 seconds' and region=coalesce(payload->>'region','konyaalti') limit 200)l join public.kiyi_regions r on r.id=l.region join public.kiyi_privacy q on q.user_id=l.user_id where q.sharing and not kiyi_private.blocked(u,l.user_id) and (q.visibility='all' or l.user_id=u or u=any(q.approved))),'[]'));
 elsif action='preferences' then
  pref=coalesce(payload->'preferences','{}');if octet_length(pref::text)>10000 then raise exception 'Tercihler çok büyük.';end if;
  insert into public.kiyi_preferences values(u,pref) on conflict(user_id) do update set preferences=excluded.preferences;return jsonb_build_object('ok',true);
 elsif action='bundle' then
  return jsonb_build_object('me',kiyi_private.person(u),'premium',is_premium,'balance',(select balance from public.kiyi_wallets where user_id=u),'inventory',coalesce((select jsonb_agg(sku) from public.kiyi_inventory where owner=u),'[]'),'following',coalesce((select jsonb_agg(target) from public.kiyi_follows where follower=u),'[]'),'followers',coalesce((select jsonb_agg(follower) from public.kiyi_follows where target=u),'[]'),'favorites',coalesce((select jsonb_agg(target) from public.kiyi_favorites where owner=u),'[]'),'blocked',coalesce((select jsonb_agg(target) from public.kiyi_blocks where owner=u),'[]'),'privacy',(select to_jsonb(q) from public.kiyi_privacy q where user_id=u),'preferences',coalesce((select preferences from public.kiyi_preferences where user_id=u),'{}'),'verification',(select to_jsonb(vr) from public.kiyi_verifications vr where user_id=u),
   'gifts',coalesce((select jsonb_agg(to_jsonb(g)||jsonb_build_object('senderProfile',kiyi_private.person(g.sender),'recipientProfile',kiyi_private.person(g.recipient))) from (select * from public.kiyi_gifts where (sender=u or recipient=u) and not kiyi_private.blocked(sender,recipient) order by created desc limit 100)g),'[]'),
   'notifications',coalesce((select jsonb_agg(to_jsonb(n)) from (select * from public.kiyi_notifications where recipient=u and not kiyi_private.blocked(sender,u) order by created desc limit 100)n),'[]'),'ledger',coalesce((select jsonb_agg(to_jsonb(l)) from(select * from public.kiyi_ledger where owner=u order by created_at desc limit 100)l),'[]'));
 else raise exception 'Desteklenmeyen işlem.';end if;
end $function$

