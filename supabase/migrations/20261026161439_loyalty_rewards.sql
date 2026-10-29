begin;
-- The existing wallet, ledger, catalog and purchasing functions are never replaced.
create table kiyi_private.reward_backup(name text primary key,definition text not null);
insert into kiyi_private.reward_backup values('command',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure));
create table kiyi_private.reward_settings(id boolean primary key default true check(id),started_at timestamptz not null default now(),salt text not null default encode(extensions.gen_random_bytes(32),'hex'),daily integer[] not null check(array_length(daily,1)=30),referral_amount int not null default 75 check(referral_amount between 0 and 500),monthly_cap int not null default 5 check(monthly_cap between 0 and 5));
insert into kiyi_private.reward_settings(daily) values(array[5,5,10,5,5,10,30,5,5,20,5,5,5,30,5,10,5,5,10,20,30,5,5,5,5,10,5,5,10,40]);
create table kiyi_private.reward_rules(code text primary key,title text not null,category text not null,threshold int not null check(threshold>0),amount int not null check(amount between 0 and 500),position int not null);
insert into kiyi_private.reward_rules values
 ('first_vehicle','İlk Anahtar','garage',1,15,1),('double_garage','Çifte Garaj','garage',2,20,2),('triple_garage','Üçlü Garaj','garage',3,30,3),('first_car','Dört Teker','car',1,0,4),('first_motorcycle','İki Teker','motorcycle',1,0,5),
 ('profile_complete','Profilini tamamla','profile',1,10,6),('first_post','İlk Gönderi','post',1,10,7),('first_video','İlk Video','video',1,10,8),('ten_posts','10 Gönderi','post',10,15,9),('twentyfive_posts','25 Gönderi','post',25,25,10),('ten_followers','10 Takipçi','follower',10,10,11),('hundred_followers','100 Takipçi','follower',100,25,12),('first_customization','İlk Özelleştirme','customization',1,5,13);
create table kiyi_private.reward_identity(identity_key text primary key,owner uuid unique references auth.users on delete set null,invite_used boolean not null default false,created_at timestamptz not null default now());
create table kiyi_private.reward_awards(identity_key text not null references kiyi_private.reward_identity,award_key text not null,owner uuid references auth.users on delete set null,amount int not null check(amount>=0),ledger_id uuid unique,legacy boolean not null default false,created_at timestamptz not null default now(),primary key(identity_key,award_key));
create index reward_awards_owner on kiyi_private.reward_awards(owner,created_at desc);
create table kiyi_private.reward_legacy(owner uuid primary key references auth.users on delete cascade,codes text[] not null);
create table kiyi_private.reward_days(owner uuid references auth.users on delete cascade,day date not null,primary key(owner,day));
create table kiyi_private.reward_daily(owner uuid primary key references auth.users on delete cascade,last_day date,streak int not null default 0 check(streak>=0));
create table kiyi_private.reward_vehicles(owner uuid references auth.users on delete cascade,plate_hash text not null,kind text not null check(kind in ('car','motorcycle')),primary key(owner,plate_hash));
create table kiyi_private.reward_codes(owner uuid primary key references auth.users on delete cascade,code text not null unique default upper(encode(extensions.gen_random_bytes(8),'hex')));
create table kiyi_private.reward_invites(invitee uuid primary key references auth.users on delete cascade,referrer uuid not null references auth.users on delete cascade,identity_key text not null unique references kiyi_private.reward_identity,created_at timestamptz not null default now(),paid_at timestamptz,check(invitee<>referrer));
create index reward_invites_referrer on kiyi_private.reward_invites(referrer,created_at desc);
create table kiyi_private.reward_config_audit(id uuid primary key default gen_random_uuid(),actor uuid references auth.users on delete set null,before_value jsonb not null,after_value jsonb not null,reason text not null,created_at timestamptz not null default now());
do $$declare t text;begin foreach t in array array['reward_backup','reward_settings','reward_rules','reward_identity','reward_awards','reward_legacy','reward_days','reward_daily','reward_vehicles','reward_codes','reward_invites','reward_config_audit'] loop execute format('alter table kiyi_private.%I enable row level security',t);execute format('revoke all on kiyi_private.%I from public,anon,authenticated',t);end loop;end$$;
alter table public.kiyi_badges drop constraint kiyi_badges_code_check;
alter table public.kiyi_badges add constraint kiyi_badges_code_check check(code in ('first_vehicle','first_post','ten_posts','hundred_followers','verified','double_garage','triple_garage','first_car','first_motorcycle','profile_complete','first_video','twentyfive_posts','ten_followers','first_customization'));

create function kiyi_private.reward_identity_for(u uuid) returns text language plpgsql security definer set search_path='' as $$
declare email text;k text;existing uuid;begin
 select lower(trim(a.email)) into email from auth.users a where a.id=u and a.email_confirmed_at is not null and not coalesce(a.is_anonymous,false);
 if email is null then raise exception 'Ödüller için e-posta adresini doğrula.' using errcode='42501';end if;
 select identity_key into k from kiyi_private.reward_identity where owner=u;if k is not null then return k;end if;
 -- Canonical aliases reduce self-invites; this is not a claim of identity verification.
 email=split_part(split_part(email,'@',1),'+',1)||'@'||replace(split_part(email,'@',2),'googlemail.com','gmail.com');
 if split_part(email,'@',2)='gmail.com' then email=replace(split_part(email,'@',1),'.','')||'@gmail.com';end if;
 select encode(extensions.hmac(email,salt,'sha256'),'hex') into k from kiyi_private.reward_settings;
 insert into kiyi_private.reward_identity(identity_key,owner) values(k,u) on conflict(identity_key) do nothing;
 select owner into existing from kiyi_private.reward_identity where identity_key=k;
 if existing is not null and existing<>u then raise exception 'Bu doğrulanmış kimlik için ödül hesabı zaten var.' using errcode='42501';end if;
 update kiyi_private.reward_identity set owner=u where identity_key=k and owner is null;
 return k;
end$$;
create function kiyi_private.reward_day_next(last_day date,streak int,today date) returns int language sql immutable set search_path='' as $$select case when last_day=today then streak when last_day=today-1 then streak+1 else 1 end$$;
create function kiyi_private.reward_pay(u uuid,k text,coins int,old boolean default false) returns boolean language plpgsql security definer set search_path='' as $$
declare identity text;rid uuid=gen_random_uuid();changed int;begin
 if coins<0 or coins>500 then raise exception 'Geçersiz ödül.';end if;
 identity=kiyi_private.reward_identity_for(u);
 insert into kiyi_private.reward_awards(identity_key,award_key,owner,amount,ledger_id,legacy) values(identity,k,u,case when old then 0 else coins end,case when coins>0 and not old then rid else null end,old) on conflict do nothing;
 get diagnostics changed=row_count;if changed=0 then return false;end if;
 if coins>0 and not old then
 insert into public.kiyi_wallets(user_id,balance)values(u,0)on conflict do nothing;
 update public.kiyi_wallets set balance=balance+coins where user_id=u;
 insert into public.kiyi_ledger(id,owner,request_id,amount,kind,reference) values(rid,u,rid,coins,'reward',k);
 end if;return true;
end$$;
create function kiyi_private.reward_metrics(u uuid,baseline boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare g int;c int;m int;p int;v int;f int;profile_ok int;custom int;begin
 select count(*),count(*)filter(where kind='car'),count(*)filter(where kind='motorcycle') into g,c,m from kiyi_private.reward_vehicles where owner=u;
 select count(*),count(*)filter(where media is not null and exists(select 1 from kiyi_private.media_registry mr where mr.path=q.media and mr.state='ready' and mr.mime like 'video/%')) into p,v from (
 select distinct on (md5(lower(regexp_replace(trim(s.text),'[[:space:]]+',' ','g'))||coalesce(s.media,''))) s.media,s.text from public.kiyi_posts s
 where s.author=u and not s.hidden and (baseline or (s.created<extract(epoch from(now()-interval '24 hours'))*1000 and (length(trim(s.text))>=12 or s.media is not null) and not exists(select 1 from public.kiyi_reports r where r.subject_kind='post' and r.subject_id=s.id and r.status in ('pending','in_review'))))
 order by md5(lower(regexp_replace(trim(s.text),'[[:space:]]+',' ','g'))||coalesce(s.media,'')),s.created limit 25)q;
 select count(*) into f from (select distinct coalesce(i.identity_key,a.id::text) from public.kiyi_follows x join auth.users a on a.id=x.follower left join kiyi_private.reward_identity i on i.owner=a.id
 where x.target=u and kiyi_private.account_active(a.id) and not kiyi_private.blocked(a.id,u) and (baseline or (a.email_confirmed_at is not null and a.created_at<now()-interval '7 days' and x.created_at<now()-interval '24 hours' and (select count(*) from kiyi_private.reward_days where owner=a.id)>=3)) limit 100)q;
 select case when length(trim(coalesce(profile->>'ownerName','')))>1 and length(trim(coalesce(profile->>'bio','')))>9 and coalesce(nullif(profile->>'avatar',''),nullif(profile->>'photo','')) is not null then 1 else 0 end into profile_ok from public.kiyi_profiles where user_id=u and deleted_at is null;
 select case when exists(select 1 from public.kiyi_vehicle_customizations vc join public.kiyi_vehicles ve on ve.id=vc.vehicle_id where ve.owner=u and vc.appearance<>'{}'::jsonb and (vc.version>1 or baseline)) or exists(select 1 from public.kiyi_ledger where owner=u and kind in ('appearance','vehicle_parts') and amount<0) then 1 else 0 end into custom;
 return jsonb_build_object('garage',g,'car',c,'motorcycle',m,'post',p,'video',v,'follower',f,'profile',coalesce(profile_ok,0),'customization',custom);
end$$;
create function kiyi_private.reward_sync(u uuid,baseline boolean default false) returns void language plpgsql security definer set search_path='' as $$
declare metrics jsonb;r record;paid boolean;begin
 if not kiyi_private.account_active(u) or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null) then return;end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 begin perform kiyi_private.reward_identity_for(u);exception when insufficient_privilege then return;end;
 metrics=kiyi_private.reward_metrics(u,baseline);
 for r in select * from kiyi_private.reward_rules order by position loop
 if (metrics->>r.category)::int>=r.threshold or (baseline and exists(select 1 from public.kiyi_badges where owner=u and code=r.code)) then
 paid=kiyi_private.reward_pay(u,'achievement:'||r.code,r.amount,baseline or exists(select 1 from kiyi_private.reward_legacy where owner=u and r.code=any(codes)));
 insert into public.kiyi_badges(owner,code)values(u,r.code)on conflict do nothing;
 -- Do not replay historical badge notices. Existing social triggers still own their notices.
 end if;end loop;
end$$;
create function kiyi_private.reward_vehicle_event() returns trigger language plpgsql security definer set search_path='' as $$
begin if new.deleted_at is null and new.model_id is not null and new.plate_key is not null then
 insert into kiyi_private.reward_vehicles values(new.owner,md5(new.plate_key),new.kind)on conflict do nothing;
 end if;return new;end$$;
create trigger reward_vehicle_history after insert or update of plate,model_id on public.kiyi_vehicles for each row execute function kiyi_private.reward_vehicle_event();
insert into kiyi_private.reward_vehicles select owner,md5(plate_key),kind from public.kiyi_vehicles where plate_key is not null and model_id is not null on conflict do nothing;
-- Existing verified achievements get a zero-value consumed record. No balance is changed.
insert into kiyi_private.reward_legacy select p.user_id,array(select r.code from kiyi_private.reward_rules r where (kiyi_private.reward_metrics(p.user_id,true)->>r.category)::int>=r.threshold or exists(select 1 from public.kiyi_badges b where b.owner=p.user_id and b.code=r.code)) from public.kiyi_profiles p where p.deleted_at is null;
select kiyi_private.reward_sync(user_id,true) from public.kiyi_profiles where deleted_at is null;

create function kiyi_private.reward_settle(u uuid) returns void language plpgsql security definer set search_path='' as $$
declare r record;n int;coins int;cap int;month_start timestamptz=date_trunc('month',now() at time zone 'Europe/Istanbul') at time zone 'Europe/Istanbul';begin
 if not kiyi_private.account_active(u) then return;end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 select referral_amount,monthly_cap into coins,cap from kiyi_private.reward_settings;
 select count(*) into n from kiyi_private.reward_awards where owner=u and award_key like 'invite:%' and not legacy and created_at>=month_start;
 for r in select * from kiyi_private.reward_invites where referrer=u and paid_at is null order by created_at,invitee loop
 exit when n>=cap;
 if not kiyi_private.account_active(r.invitee) or kiyi_private.blocked(u,r.invitee) or not exists(select 1 from auth.users where id=r.invitee and email_confirmed_at is not null) then continue;end if;
 if (select count(*)from kiyi_private.reward_days where owner=r.invitee and day>=(r.created_at at time zone 'Europe/Istanbul')::date)<3 then continue;end if;
 if kiyi_private.reward_pay(u,'invite:'||r.identity_key,coins) then n=n+1;end if;
 update kiyi_private.reward_invites set paid_at=now() where invitee=r.invitee;
 end loop;
end$$;
create function kiyi_private.reward_activity(u uuid) returns void language plpgsql security definer set search_path='' as $$
declare parent uuid;begin
 if not kiyi_private.account_active(u) or not exists(select 1 from auth.users where id=u and email_confirmed_at is not null) then return;end if;
 begin perform kiyi_private.reward_identity_for(u);exception when insufficient_privilege then return;end;
 insert into kiyi_private.reward_days values(u,(now() at time zone 'Europe/Istanbul')::date)on conflict do nothing;
 perform kiyi_private.reward_sync(u);
 select referrer into parent from kiyi_private.reward_invites where invitee=u and paid_at is null;
 if parent is not null then perform kiyi_private.reward_settle(parent);end if;
end$$;

create function kiyi_private.reward_command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();k text;today date=(now() at time zone 'Europe/Istanbul')::date;d kiyi_private.reward_daily;next_streak int;idx int;coins int;code_value text;referrer_id uuid;metrics jsonb;before_value jsonb;after_value jsonb;begin
 if not kiyi_private.session_live(u) or not kiyi_private.account_active(u) or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'Geçerli bir hesap ve oturum gerekiyor.' using errcode='42501';end if;
 perform kiyi_private.social_rate(u,'rewards:'||action,case when action='reward_referral' then 5 else 15 end);
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if action='reward_admin' then
 perform kiyi_private.admin_authorize('settings',true);
 if length(trim(coalesce(payload->>'reason','')))<10 then raise exception 'Değişiklik nedeni gerekli.';end if;
 select jsonb_build_object('daily',daily,'referral_amount',referral_amount,'monthly_cap',monthly_cap,'rules',(select jsonb_object_agg(code,amount)from kiyi_private.reward_rules)) into before_value from kiyi_private.reward_settings;
 if payload?'daily' then if jsonb_typeof(payload->'daily')<>'array' or jsonb_array_length(payload->'daily')<>30 or exists(select 1 from jsonb_array_elements_text(payload->'daily')x where x::int not between 0 and 500) then raise exception '30 günlük geçerli takvim gerekiyor.';end if;update kiyi_private.reward_settings set daily=array(select x::int from jsonb_array_elements_text(payload->'daily')x);end if;
 if payload?'referral_amount' then update kiyi_private.reward_settings set referral_amount=(payload->>'referral_amount')::int;end if;
 if payload?'monthly_cap' then update kiyi_private.reward_settings set monthly_cap=(payload->>'monthly_cap')::int;end if;
 if payload?'rules' then update kiyi_private.reward_rules r set amount=(payload->'rules'->>r.code)::int where payload->'rules'?r.code;end if;
 select jsonb_build_object('daily',daily,'referral_amount',referral_amount,'monthly_cap',monthly_cap,'rules',(select jsonb_object_agg(code,amount)from kiyi_private.reward_rules)) into after_value from kiyi_private.reward_settings;
 insert into kiyi_private.reward_config_audit(actor,before_value,after_value,reason)values(u,before_value,after_value,left(payload->>'reason',400));return '{"ok":true}';end if;
 if not exists(select 1 from auth.users where id=u and email_confirmed_at is not null) then
 if action='rewards' then return jsonb_build_object('verification_required',true);end if;
 raise exception 'Ödüller için e-posta adresini doğrula.' using errcode='42501';end if;
 k=kiyi_private.reward_identity_for(u);
 insert into kiyi_private.reward_codes(owner)values(u)on conflict do nothing;
 if action='reward_referral' then
 code_value=upper(regexp_replace(coalesce(payload->>'code',''),'[[:space:]-]','','g'));
 if code_value !~ '^[A-F0-9]{16}$' then raise exception 'Geçersiz davet kodu.' using errcode='22023';end if;
 select owner into referrer_id from kiyi_private.reward_codes where code=code_value;
 if referrer_id is null or referrer_id=u or not kiyi_private.account_active(referrer_id) or kiyi_private.blocked(u,referrer_id) then raise exception 'Bu davet kullanılamaz.' using errcode='22023';end if;
 if exists(select 1 from kiyi_private.reward_invites where invitee=u) then
 if exists(select 1 from kiyi_private.reward_invites where invitee=u and referrer=referrer_id) then return '{"ok":true,"already_bound":true}';end if;
 raise exception 'Hesabına zaten bir davet bağlanmış.' using errcode='22023';end if;
 if not exists(select 1 from auth.users a,auth.users b,kiyi_private.reward_settings s where a.id=u and b.id=referrer_id and a.created_at>=s.started_at and a.created_at>now()-interval '7 days' and b.created_at<a.created_at) then raise exception 'Davetler yalnızca yeni hesaplara bağlanabilir.' using errcode='22023';end if;
 if exists(select 1 from kiyi_private.reward_days where owner=u) then raise exception 'Davet kodunu ilk aktif kullanımından önce ekle.' using errcode='22023';end if;
 update kiyi_private.reward_identity set invite_used=true where identity_key=k and not invite_used;if not found then raise exception 'Bu kimlik için davet daha önce kullanılmış.' using errcode='22023';end if;
 insert into kiyi_private.reward_invites(invitee,referrer,identity_key)values(u,referrer_id,k);return '{"ok":true}';
 elsif action='reward_daily' then
 insert into kiyi_private.reward_daily(owner)values(u)on conflict do nothing;
 select * into d from kiyi_private.reward_daily where owner=u for update;
 if d.last_day=today then return jsonb_build_object('ok',true,'already_claimed',true,'balance',(select balance from public.kiyi_wallets where user_id=u));end if;
 next_streak=kiyi_private.reward_day_next(d.last_day,d.streak,today);idx=(next_streak-1)%30+1;
 select daily[idx] into coins from kiyi_private.reward_settings;
 if not kiyi_private.reward_pay(u,'daily:'||today::text,coins) then return jsonb_build_object('ok',true,'already_claimed',true);end if;
 update kiyi_private.reward_daily set last_day=today,streak=next_streak where owner=u;
 perform kiyi_private.reward_activity(u);
 return jsonb_build_object('ok',true,'amount',coins,'day',idx,'streak',next_streak,'balance',(select balance from public.kiyi_wallets where user_id=u));
 elsif action<>'rewards' then raise exception 'Geçersiz ödül işlemi.';end if;
 perform kiyi_private.reward_sync(u);perform kiyi_private.reward_settle(u);
 select * into d from kiyi_private.reward_daily where owner=u;
 next_streak=kiyi_private.reward_day_next(d.last_day,coalesce(d.streak,0),today);idx=(next_streak-1)%30+1;metrics=kiyi_private.reward_metrics(u);
 return jsonb_build_object('verified',coalesce((select verified from public.kiyi_entitlements where user_id=u),false),'today',today,'timezone','Europe/Istanbul','claimed',coalesce(d.last_day=today,false),'day',idx,'streak',case when d.last_day>=today-1 then d.streak else 0 end,'calendar',(select to_jsonb(daily)from kiyi_private.reward_settings),'code',(select code from kiyi_private.reward_codes where owner=u),'balance',(select balance from public.kiyi_wallets where user_id=u),
 'referral_amount',(select referral_amount from kiyi_private.reward_settings),'monthly_cap',(select monthly_cap from kiyi_private.reward_settings),'referral_earned',(select coalesce(sum(amount),0) from kiyi_private.reward_awards where owner=u and award_key like 'invite:%'),
 'invites',coalesce((select jsonb_agg(jsonb_build_object('number',q.n,'days',q.days,'paid',q.paid_at is not null,'created_at',q.created_at))from(select row_number()over(order by created_at) n,created_at,paid_at,(select count(*)from kiyi_private.reward_days activity where activity.owner=i.invitee and activity.day>=(i.created_at at time zone 'Europe/Istanbul')::date) days from kiyi_private.reward_invites i where referrer=u order by created_at desc limit 100)q),'[]'),
 'achievements',coalesce((select jsonb_agg(jsonb_build_object('code',r.code,'title',r.title,'category',r.category,'threshold',r.threshold,'amount',r.amount,'progress',least(r.threshold,(metrics->>r.category)::int),'earned',a.award_key is not null,'legacy',coalesce(a.legacy,false))order by r.position)from kiyi_private.reward_rules r left join kiyi_private.reward_awards a on a.identity_key=k and a.award_key='achievement:'||r.code),'[]'));
end$$;
create function kiyi_private.reward_erasure() returns trigger language plpgsql security definer set search_path='' as $$
begin if new.deleted_at is not null and old.deleted_at is null then
 delete from kiyi_private.reward_days where owner=new.user_id;delete from kiyi_private.reward_daily where owner=new.user_id;
 delete from kiyi_private.reward_vehicles where owner=new.user_id;delete from kiyi_private.reward_codes where owner=new.user_id;
 delete from kiyi_private.reward_invites where invitee=new.user_id or referrer=new.user_id;
 delete from kiyi_private.reward_legacy where owner=new.user_id;
 end if;return new;end$$;
create trigger reward_account_erasure after update of deleted_at on public.kiyi_profiles for each row execute function kiyi_private.reward_erasure();
-- Existing function remains the guarded implementation for all non-reward commands.
alter function kiyi_private.command(text,jsonb) rename to command_before_rewards;
revoke all on function kiyi_private.command_before_rewards(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare r jsonb;begin
 if action in ('rewards','reward_daily','reward_referral','reward_admin') then perform kiyi_private.command_before_rewards('__stage7_guard','{}');return kiyi_private.reward_command(action,payload);end if;
 r=kiyi_private.command_before_rewards(action,payload);
 if action in ('profile','vehicle_create','vehicle_update','vehicle_parts','vehicle_apply','vehicle_customize','vehicle_part_purchase','post_create','comment_create','comment','follow','gift','appearance') then perform kiyi_private.reward_activity(auth.uid());end if;
 return r;
end$$;
do $$declare f record;begin for f in select p.oid::regprocedure signature from pg_proc p where pronamespace='kiyi_private'::regnamespace and proname like 'reward_%' loop execute format('revoke all on function %s from public,anon,authenticated',f.signature);end loop;end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
