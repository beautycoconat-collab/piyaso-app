begin;
create table kiyi_private.badge_backup(name text primary key,definition text not null);
insert into kiyi_private.badge_backup values('command',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure));
create table kiyi_private.badge_catalog(code text primary key,family text not null,title text not null,category text not null,level text,metric text not null,threshold int not null check(threshold>0),condition text not null,image text,locked_image text,position int not null);
create table kiyi_private.badge_earned(owner uuid references auth.users on delete cascade,code text references kiyi_private.badge_catalog,earned_at timestamptz not null default now(),active boolean not null default true,primary key(owner,code));
create table kiyi_private.badge_map_days(owner uuid references auth.users on delete cascade,region text not null check(region in('konyaalti','lara','kultur')),day date not null,primary key(owner,region,day));
create table kiyi_private.badge_facts(owner uuid references auth.users on delete cascade,code text not null,created_at timestamptz not null default now(),primary key(owner,code));
create table kiyi_private.badge_invalidations(kind text not null check(kind in('gift','post','comment','invite')),subject uuid not null,actor uuid not null,reason text not null,created_at timestamptz not null default now(),primary key(kind,subject));
do $$declare t text;begin foreach t in array array['badge_backup','badge_catalog','badge_earned','badge_map_days','badge_facts','badge_invalidations']loop execute format('alter table kiyi_private.%I enable row level security',t);execute format('revoke all on kiyi_private.%I from public,anon,authenticated',t);end loop;end$$;
insert into kiyi_private.badge_catalog(code,family,title,category,level,metric,threshold,condition,image,locked_image,position) values
('post_silver','post','Gönderi','explore','Gümüş','post',1,'1 geçerli gönderi','assets/badges/39_ilk_gonderi_gumus.webp','assets/badges/39_ilk_gonderi_gumus.webp',0),
('post_copper','post','Gönderi','explore','Bakır','post',10,'10 geçerli gönderi','assets/badges/37_ilk_gonderi_bakir.webp','assets/badges/39_ilk_gonderi_gumus.webp',1),
('post_gold','post','Gönderi','explore','Altın','post',50,'50 geçerli gönderi','assets/badges/13_ilk_gonderi_altin.webp','assets/badges/39_ilk_gonderi_gumus.webp',2),
('post_ultra','post','Gönderi','explore','Ultra','post',200,'200 geçerli gönderi',null,'assets/badges/39_ilk_gonderi_gumus.webp',3),
('like_silver','like','Beğeni','explore','Gümüş','like',10,'10 geçerli beğeni','assets/badges/11_begeni_gumus.webp','assets/badges/11_begeni_gumus.webp',4),
('like_copper','like','Beğeni','explore','Bakır','like',50,'50 geçerli beğeni','assets/badges/29_begeni_bakir.webp','assets/badges/11_begeni_gumus.webp',5),
('like_gold','like','Beğeni','explore','Altın','like',250,'250 geçerli beğeni','assets/badges/07_begeni_altin.webp','assets/badges/11_begeni_gumus.webp',6),
('like_ultra','like','Beğeni','explore','Ultra','like',1000,'1.000 geçerli beğeni',null,'assets/badges/11_begeni_gumus.webp',7),
('song_silver','song','Şarkı Gönder','community','Gümüş','song',1,'1 başarılı şarkı','assets/badges/05_sarki_gonder_gumus.webp','assets/badges/05_sarki_gonder_gumus.webp',8),
('song_copper','song','Şarkı Gönder','community','Bakır','song',5,'5 başarılı şarkı','assets/badges/14_sarki_gonder_bakir.webp','assets/badges/05_sarki_gonder_gumus.webp',9),
('song_gold','song','Şarkı Gönder','community','Altın','song',20,'20 başarılı şarkı','assets/badges/19_sarki_gonder_altin.webp','assets/badges/05_sarki_gonder_gumus.webp',10),
('song_ultra','song','Şarkı Gönder','community','Ultra','song',75,'75 başarılı şarkı',null,'assets/badges/05_sarki_gonder_gumus.webp',11),
('gift_silver','gift','Hediye Gönder','community','Gümüş','gift',1,'1 başarılı hediye','assets/badges/08_hediye_gonder_gumus.webp','assets/badges/08_hediye_gonder_gumus.webp',12),
('gift_copper','gift','Hediye Gönder','community','Bakır','gift',5,'5 başarılı hediye','assets/badges/06_hediye_gonder_bakir.webp','assets/badges/08_hediye_gonder_gumus.webp',13),
('gift_gold','gift','Hediye Gönder','community','Altın','gift',20,'20 başarılı hediye','assets/badges/20_hediye_gonder_altin.webp','assets/badges/08_hediye_gonder_gumus.webp',14),
('gift_ultra','gift','Hediye Gönder','community','Ultra','gift',75,'75 başarılı hediye',null,'assets/badges/08_hediye_gonder_gumus.webp',15),
('comment_silver','comment','Yorum','community','Gümüş','comment',1,'1 geçerli yorum','assets/badges/27_yorum_gumus.webp','assets/badges/27_yorum_gumus.webp',16),
('comment_copper','comment','Yorum','community','Bakır','comment',5,'5 geçerli yorum','assets/badges/31_yorum_bakir.webp','assets/badges/27_yorum_gumus.webp',17),
('comment_gold','comment','Yorum','community','Altın','comment',20,'20 geçerli yorum','assets/badges/18_yorum_altin.webp','assets/badges/27_yorum_gumus.webp',18),
('comment_ultra','comment','Yorum','community','Ultra','comment',76,'76 geçerli yorum',null,'assets/badges/27_yorum_gumus.webp',19),
('invite_silver','invite','Arkadaşını Davet Et','community','Gümüş','invite',1,'1 doğrulanmış davet','assets/badges/16_arkadasini_davet_et_gumus.webp','assets/badges/16_arkadasini_davet_et_gumus.webp',20),
('invite_copper','invite','Arkadaşını Davet Et','community','Bakır','invite',3,'3 doğrulanmış davet',null,'assets/badges/16_arkadasini_davet_et_gumus.webp',21),
('invite_gold','invite','Arkadaşını Davet Et','community','Altın','invite',10,'10 doğrulanmış davet',null,'assets/badges/16_arkadasini_davet_et_gumus.webp',22),
('invite_ultra','invite','Arkadaşını Davet Et','community','Ultra','invite',25,'25 doğrulanmış davet',null,'assets/badges/16_arkadasini_davet_et_gumus.webp',23),
('map_silver','map','Haritada Görün','map','Gümüş','map_konyaalti',1,'Konyaaltı’nda 1 farklı gün görün','assets/badges/28_haritada_gorun_gumus.webp','assets/badges/28_haritada_gorun_gumus.webp',24),
('map_copper','map','Haritada Görün','map','Bakır','map_lara',3,'Lara’da 3 farklı gün görün',null,'assets/badges/28_haritada_gorun_gumus.webp',25),
('map_gold','map','Haritada Görün','map','Altın','map_kultur',5,'Kültür’de 5 farklı gün görün',null,'assets/badges/28_haritada_gorun_gumus.webp',26),
('map_ultra','map','Haritada Görün','map','Ultra','map_total',30,'Üç bölgede de görün; toplam 30 bölge-gün',null,'assets/badges/28_haritada_gorun_gumus.webp',27),
('first_vehicle','first_vehicle','İlk Anahtar','garage',null,'garage',1,'1 farklı araç ekle','assets/badges/01_ilk_arac_renkli.webp','assets/badges/38_ilk_arac_gumus.webp',28),
('double_garage','double_garage','Çifte Garaj','garage',null,'garage',2,'2 farklı araç ekle','assets/badges/02_cifte_garaj_renkli.webp','assets/badges/30_cifte_garaj_gumus.webp',29),
('triple_garage','triple_garage','Üçlü Garaj','garage',null,'garage',3,'3 farklı araç ekle',null,null,30),
('first_car','first_car','Dört Teker','garage',null,'car',1,'1 otomobil ekle','assets/badges/01_ilk_arac_renkli.webp','assets/badges/38_ilk_arac_gumus.webp',31),
('first_motorcycle','first_motorcycle','İlk Motosiklet','garage',null,'motorcycle',1,'1 motosiklet ekle','assets/badges/03_ilk_motosiklet_renkli.webp','assets/badges/26_ilk_motosiklet_gumus.webp',32),
('first_post','first_post','İlk Gönderi','explore',null,'post',1,'1 geçerli gönderi paylaş','assets/badges/23_ilk_gonderi_renkli.webp','assets/badges/39_ilk_gonderi_gumus.webp',33),
('ten_posts','ten_posts','10 Gönderi','explore',null,'post',10,'10 geçerli gönderi paylaş','assets/badges/23_ilk_gonderi_renkli.webp','assets/badges/39_ilk_gonderi_gumus.webp',34),
('twentyfive_posts','twentyfive_posts','25 Gönderi','explore',null,'post',25,'25 geçerli gönderi paylaş','assets/badges/23_ilk_gonderi_renkli.webp','assets/badges/39_ilk_gonderi_gumus.webp',35),
('first_video','first_video','İlk Video','explore',null,'video',1,'1 geçerli video paylaş',null,null,36),
('first_photo','first_photo','İlk Fotoğraf','explore',null,'photo',1,'1 geçerli fotoğraf paylaş',null,null,37),
('ten_followers','ten_followers','10 Takipçi','community',null,'follower',10,'10 uygun takipçiye ulaş','assets/badges/12_topluluk_aktif_uyesi_renkli.webp','assets/badges/17_topluluk_aktif_uyesi_gumus.webp',38),
('hundred_followers','hundred_followers','100 Takipçi','community',null,'follower',100,'100 uygun takipçiye ulaş','assets/badges/12_topluluk_aktif_uyesi_renkli.webp','assets/badges/17_topluluk_aktif_uyesi_gumus.webp',39),
('profile_complete','profile_complete','Profil Tamamlandı','special',null,'profile',1,'Profil bilgilerini tamamla',null,null,40),
('first_customization','first_customization','İlk Özelleştirme','special',null,'customization',1,'İlk araç özelleştirmeni tamamla',null,null,41),
('verified','verified','Onaylı Hesap','special',null,'verified',1,'Profil doğrulamanı tamamla','assets/badges/04_onayli_hesap_renkli.webp','assets/badges/10_onayli_hesap_gumus.webp',42),
('daily_entry','daily_entry','Günlük Giriş','special',null,'daily',1,'Günlük ödülünü al','assets/badges/36_gunluk_giris_renkli.webp','assets/badges/09_gunluk_giris_gumus.webp',43),
('ghost_mode','ghost_mode','Hayalet Mod','special',null,'ghost',1,'Hayalet modunu etkinleştir','assets/badges/35_hayalet_mod_renkli.webp','assets/badges/15_hayalet_mod_gumus.webp',44),
('premium_member','premium_member','Premium Üye','special',null,'premium',1,'Premium üyeliğini etkinleştir','assets/badges/24_premium_uye_renkli.webp','assets/badges/21_premium_uye_gumus.webp',45);
create function kiyi_private.badge_valid_posts(u uuid) returns table(id uuid,media text) language sql stable security definer set search_path='' as $$
 select distinct on(md5(lower(regexp_replace(trim(p.text),'[[:space:]]+',' ','g'))||coalesce(p.media,''))) p.id,p.media from public.kiyi_posts p
 where p.author=u and not p.hidden and p.created<extract(epoch from now()-interval '24 hours')*1000
 and (length(trim(p.text))>=12 or p.media is not null)
 and (p.media is null or exists(select 1 from kiyi_private.media_registry m where m.path=p.media and m.owner=u and m.state='ready'))
 and not exists(select 1 from public.kiyi_reports r where r.subject_kind='post' and r.subject_id=p.id and r.status in('pending','in_review'))
 and not exists(select 1 from kiyi_private.badge_invalidations i where i.kind='post' and i.subject=p.id)
 order by md5(lower(regexp_replace(trim(p.text),'[[:space:]]+',' ','g'))||coalesce(p.media,'')),p.created,p.id
$$;
create function kiyi_private.badge_metrics(u uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare metrics jsonb;posts int;photos int;videos int;likes int;comments int;gifts int;songs int;invites int;mk int;ml int;mc int;base_metrics jsonb;begin
 base_metrics=kiyi_private.reward_metrics(u);
 select count(*),count(*)filter(where exists(select 1 from kiyi_private.media_registry m where m.path=p.media and m.mime like 'image/%')),count(*)filter(where exists(select 1 from kiyi_private.media_registry m where m.path=p.media and m.mime like 'video/%')) into posts,photos,videos from kiyi_private.badge_valid_posts(u)p;
 select count(*) into likes from public.kiyi_likes l join kiyi_private.badge_valid_posts(u)p on p.id=l.post join auth.users a on a.id=l.person where l.person<>u and a.email_confirmed_at is not null and a.created_at<now()-interval '24 hours' and kiyi_private.account_active(l.person) and not kiyi_private.blocked(u,l.person);
 select count(*) into comments from (select distinct lower(regexp_replace(trim(c.text),'[[:space:]]+',' ','g')) from public.kiyi_comments c join public.kiyi_posts p on p.id=c.post where c.author=u and not c.hidden and not p.hidden and kiyi_private.account_active(p.author) and not kiyi_private.blocked(u,p.author) and length(trim(c.text))>=3 and c.created<extract(epoch from now()-interval '24 hours')*1000 and not exists(select 1 from public.kiyi_reports r where r.subject_kind='comment'and r.subject_id=c.id and r.status in('pending','in_review')) and not exists(select 1 from kiyi_private.badge_invalidations i where i.kind='comment'and i.subject=c.id))q;
 select count(*)filter(where g.product<>'song'),count(*)filter(where g.product='song') into gifts,songs from public.kiyi_gifts g
 where g.sender=u and g.recipient<>u and kiyi_private.account_active(g.recipient)
 and exists(select 1 from public.kiyi_ledger l where l.owner=u and l.kind='gift' and l.request_id=g.id and l.amount=-g.credits and l.reference=g.id::text)
 and not exists(select 1 from public.kiyi_ledger l where l.owner=u and l.amount>0 and l.kind in('refund','gift_refund') and (l.reference=g.id::text or l.reference='gift:'||g.id::text))
 and not exists(select 1 from kiyi_private.badge_invalidations i where i.kind='gift'and i.subject=g.id);
 select count(*) into invites from kiyi_private.reward_invites i join auth.users a on a.id=i.invitee where i.referrer=u and a.email_confirmed_at is not null and kiyi_private.account_active(i.invitee) and not kiyi_private.blocked(u,i.invitee) and (select count(*)from kiyi_private.reward_days d where d.owner=i.invitee and d.day>=(i.created_at at time zone 'Europe/Istanbul')::date)>=3 and not exists(select 1 from kiyi_private.badge_invalidations v where v.kind='invite'and v.subject=i.invitee);
 select count(*)filter(where region='konyaalti'),count(*)filter(where region='lara'),count(*)filter(where region='kultur')into mk,ml,mc from kiyi_private.badge_map_days where owner=u;
 metrics=base_metrics||jsonb_build_object('post',posts,'photo',photos,'video',videos,'like',likes,'comment',comments,'gift',gifts,'song',songs,'invite',invites,'map_konyaalti',mk,'map_lara',ml,'map_kultur',mc,'map_total',mk+ml+mc,'map_regions',(case when mk>0 then 1 else 0 end)+(case when ml>0 then 1 else 0 end)+(case when mc>0 then 1 else 0 end),'daily',case when exists(select 1 from kiyi_private.reward_awards where owner=u and award_key like 'daily:%'and not legacy)then 1 else 0 end,'verified',case when exists(select 1 from public.kiyi_entitlements where user_id=u and verified)then 1 else 0 end,'premium',case when kiyi_private.premium(u)then 1 else 0 end,'ghost',case when exists(select 1 from kiyi_private.badge_facts where owner=u and code='ghost_mode')or exists(select 1 from public.kiyi_privacy where user_id=u and ghost)then 1 else 0 end);
 return metrics;
end$$;
create function kiyi_private.badge_sync(u uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare m jsonb;r record;n int;qualified boolean;begin
 if not kiyi_private.account_active(u) then return '{}';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi-badges:'||u::text,0));m=kiyi_private.badge_metrics(u);
 for r in select * from kiyi_private.badge_catalog order by position loop
 n=coalesce((m->>r.metric)::int,0);qualified=n>=r.threshold and (r.code<>'map_ultra' or (m->>'map_regions')::int=3);
 -- Preserve old single-badge achievements; only new tiers are recalculated after invalidation/deletion.
 if r.level is null and r.code not in('verified','premium_member') and exists(select 1 from public.kiyi_badges where owner=u and code=r.code) then qualified=true;end if;
 if qualified then insert into kiyi_private.badge_earned(owner,code)values(u,r.code)on conflict(owner,code)do update set active=true;
 else update kiyi_private.badge_earned set active=false where owner=u and code=r.code;end if;
 end loop;return m;
end$$;
create function kiyi_private.badge_map_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.region in('konyaalti','lara','kultur') and new.received_at>now()-interval '90 seconds'
 and exists(select 1 from public.kiyi_privacy where user_id=new.user_id and sharing and not ghost and consented_at is not null)
 and exists(select 1 from auth.users where id=new.user_id and email_confirmed_at is not null) and kiyi_private.account_active(new.user_id) then
 insert into kiyi_private.badge_map_days(owner,region,day)values(new.user_id,new.region,(now()at time zone 'Europe/Istanbul')::date)on conflict do nothing;
 end if;return new;
end$$;
create trigger badge_map_event after insert or update on public.kiyi_positions for each row execute function kiyi_private.badge_map_event();
create function kiyi_private.badge_privacy_event() returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.ghost then insert into kiyi_private.badge_facts(owner,code)values(new.user_id,'ghost_mode')on conflict do nothing;end if;return new;end$$;
create trigger badge_privacy_event after insert or update of ghost on public.kiyi_privacy for each row execute function kiyi_private.badge_privacy_event();
create function kiyi_private.badge_erasure()returns trigger language plpgsql security definer set search_path='' as $$begin
 if new.deleted_at is not null then delete from kiyi_private.badge_map_days where owner=new.user_id;delete from kiyi_private.badge_facts where owner=new.user_id;delete from kiyi_private.badge_earned where owner=new.user_id;end if;return new;end$$;
create trigger badge_account_erasure after update of deleted_at on public.kiyi_profiles for each row execute function kiyi_private.badge_erasure();
alter function kiyi_private.command(text,jsonb)rename to command_before_badge_levels;
revoke all on function kiyi_private.command_before_badge_levels(text,jsonb)from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();t uuid;result jsonb;metrics jsonb;items jsonb;begin
 if action='badge_dashboard' then
 perform kiyi_private.command_before_rewards('__stage7_guard','{}');
 if not kiyi_private.session_live(u)or not kiyi_private.account_active(u)or coalesce((auth.jwt()->>'is_anonymous')::boolean,false)then raise exception 'Geçerli bir hesap gerekiyor.'using errcode='42501';end if;
 perform kiyi_private.social_rate(u,'badge_dashboard',20);metrics=kiyi_private.badge_sync(u);
 select jsonb_agg(to_jsonb(c)-'metric'-'position'||jsonb_build_object('progress',least(c.threshold,coalesce((metrics->>c.metric)::int,0)),'earned',coalesce(b.active,false),'earned_at',case when b.active then b.earned_at else null end,'extra_ready',c.code<>'map_ultra'or(metrics->>'map_regions')::int=3)order by c.position)into items from kiyi_private.badge_catalog c left join kiyi_private.badge_earned b on b.code=c.code and b.owner=u;
 return jsonb_build_object('items',items,'earned',(select count(*)from kiyi_private.badge_earned where owner=u and active),'total',(select count(*)from kiyi_private.badge_catalog));
 elsif action='badge_invalidate' then
 perform kiyi_private.command_before_rewards('__stage7_guard','{}');perform kiyi_private.admin_authorize('ops.write',true);
 if payload->>'kind' not in('gift','post','comment','invite')or length(trim(coalesce(payload->>'reason','')))<10 then raise exception 'Geçerli kayıt ve gerekçe gerekli.';end if;
 insert into kiyi_private.badge_invalidations(kind,subject,actor,reason)values(payload->>'kind',(payload->>'id')::uuid,u,left(payload->>'reason',400))on conflict do nothing;return '{"ok":true}';
 end if;
 result=kiyi_private.command_before_badge_levels(action,payload);
 if action='badges' then
 t=coalesce(nullif(payload->>'target','')::uuid,u);
 -- The delegated badges read already enforces profile visibility/block/ghost rules.
 if t=u then metrics=kiyi_private.badge_sync(u);else metrics=kiyi_private.badge_metrics(t);end if;
 return result||jsonb_build_object('level_badges',coalesce((select jsonb_agg(jsonb_build_object('code',b.code,'earned_at',b.earned_at,'title',c.title,'level',c.level,'image',c.image)order by c.position)from kiyi_private.badge_earned b join kiyi_private.badge_catalog c on c.code=b.code where b.owner=t and b.active and (c.level is null or (coalesce((metrics->>c.metric)::int,0)>=c.threshold and (c.code<>'map_ultra' or (metrics->>'map_regions')::int=3)))),'[]'));
 end if;return result;
end$$;
do $$declare f record;begin
 for f in select p.oid::regprocedure sig from pg_proc p where pronamespace='kiyi_private'::regnamespace and proname like 'badge_%' loop execute format('revoke all on function %s from public,anon,authenticated',f.sig);end loop;
end$$;
revoke all on function kiyi_private.command(text,jsonb)from public,anon;
grant execute on function kiyi_private.command(text,jsonb)to authenticated;
commit;

