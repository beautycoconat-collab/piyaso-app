begin;
create table kiyi_private.stage2_media_backup(key text primary key,definition text not null);
alter table kiyi_private.stage2_media_backup enable row level security;
revoke all on kiyi_private.stage2_media_backup from public,anon,authenticated;
insert into kiyi_private.stage2_media_backup values('command',pg_get_functiondef('kiyi_private.command_pre_garage(text,jsonb)'::regprocedure));
insert into kiyi_private.stage2_media_backup select 'bucket',to_jsonb(b)::text from storage.buckets b where id='kiyi-media';
create table kiyi_private.media_registry(path text primary key,owner uuid not null references auth.users on delete cascade,mime text not null,bytes bigint not null check(bytes>0),state text not null check(state in ('pending','ready','deleting')),created_at timestamptz not null default now());
create index media_registry_owner on kiyi_private.media_registry(owner);
create table kiyi_private.media_cleanup(path text primary key,created_at timestamptz not null default now());
create table kiyi_private.media_worker_secret(secret text not null);
insert into kiyi_private.media_worker_secret values(encode(extensions.gen_random_bytes(32),'hex'));
alter table kiyi_private.media_registry enable row level security;
alter table kiyi_private.media_cleanup enable row level security;
alter table kiyi_private.media_worker_secret enable row level security;
revoke all on kiyi_private.media_registry,kiyi_private.media_cleanup,kiyi_private.media_worker_secret from public,anon,authenticated;
update storage.buckets set file_size_limit=20971520,allowed_mime_types=array['image/jpeg','image/png','image/webp','audio/webm','audio/mp4','video/mp4','video/webm'] where id='kiyi-media';
-- All new bytes pass server authentication and signature checks; browser inserts cannot bypass the edge.
create policy kiyi_media_server_upload on storage.objects as restrictive for insert to authenticated with check(bucket_id<>'kiyi-media');
create function kiyi_private.media_referenced(p text) returns boolean language sql stable set search_path='' as $$select exists(select 1 from public.kiyi_posts where media=p) or exists(select 1 from public.kiyi_profiles where profile->>'avatar'=p or profile->>'photo'=p or coalesce(profile->'photos','[]')?p)$$;
revoke all on function kiyi_private.media_referenced(text) from public,anon,authenticated;
create function public.kiyi_media_worker(action text,payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid;p text;mime text;n bigint;result jsonb;
begin
 perform pg_advisory_xact_lock(hashtextextended('kiyi-media-worker',0));
 if action='reserve' then
 u=(payload->>'owner')::uuid;mime=payload->>'mime';n=(payload->>'bytes')::bigint;
 if u is null or not kiyi_private.account_active(u) then raise exception 'Hesap kullanılamıyor.';end if;
 if coalesce((select value='true'::jsonb from kiyi_private.ops_settings where key='maintenance'),false) then raise exception 'Bakım sürüyor.';end if;
 if mime is null or mime not in ('image/jpeg','image/png','image/webp','audio/webm','audio/mp4','video/mp4','video/webm') or n is null or n<=0 or n>(case when mime like 'video/%' then 20971520 else 5242880 end) then raise exception 'Dosya türü veya boyutu uygun değil.';end if;
 if (select count(*) from kiyi_private.media_registry where owner=u and created_at>now()-interval '1 hour')>=30 then raise exception 'Yükleme sıklığı sınırına ulaşıldı.';end if;
 if coalesce((select sum(bytes) from kiyi_private.media_registry where owner=u and state='pending'),0)+coalesce((select sum((metadata->>'size')::bigint) from storage.objects where bucket_id='kiyi-media' and split_part(name,'/',1)=u::text),0)+n>52428800 then raise exception 'Hesabın 50 MB medya sınırına ulaştı.';end if;
 if coalesce((select sum(bytes) from kiyi_private.media_registry where state='pending'),0)+coalesce((select sum((metadata->>'size')::bigint) from storage.objects),0)+n>524288000 then raise exception 'Proje medya bütçesi doldu.';end if;
 p=u::text||'/social/'||gen_random_uuid()::text;insert into kiyi_private.media_registry values(p,u,mime,n,'pending',now());return jsonb_build_object('path',p);
 elsif action='confirm' then
 p=payload->>'path';
 if not exists(select 1 from kiyi_private.media_registry r join storage.objects o on o.name=r.path and o.bucket_id='kiyi-media' where r.path=p and r.state='pending' and (o.metadata->>'size')::bigint=r.bytes and o.metadata->>'mimetype'=r.mime) then raise exception 'Yüklenen dosya uyuşmuyor.';end if;
 update kiyi_private.media_registry set state='ready' where path=p;return jsonb_build_object('ok',true);
 elsif action='cleanup' then
 if payload->>'secret' is distinct from (select secret from kiyi_private.media_worker_secret) then raise exception 'Yetkisiz işlem.' using errcode='42501';end if;
 with candidates as(select r.path from kiyi_private.media_registry r where not kiyi_private.media_referenced(r.path) and (r.state='deleting' or r.created_at<now()-interval '24 hours' or (r.state='pending' and r.created_at<now()-interval '1 hour') or exists(select 1 from kiyi_private.media_cleanup c where c.path=r.path)) order by r.created_at limit 50 for update)
 update kiyi_private.media_registry set state='deleting' where path in(select path from candidates);
 select coalesce(jsonb_agg(path),'[]') into result from kiyi_private.media_registry where state='deleting' and not kiyi_private.media_referenced(path);return jsonb_build_object('paths',result);
 elsif action='ack' then
 p=payload->>'path';if exists(select 1 from storage.objects where bucket_id='kiyi-media' and name=p) then raise exception 'Dosya henüz silinmedi.';end if;
 delete from kiyi_private.media_registry where path=p and state='deleting';delete from kiyi_private.media_cleanup where path=p;return '{}';
 end if;raise exception 'Geçersiz işlem.';
end$$;
revoke all on function public.kiyi_media_worker(text,jsonb) from public,anon,authenticated;grant execute on function public.kiyi_media_worker(text,jsonb) to service_role;
create function kiyi_private.stage2_media_refs() returns trigger language plpgsql security definer set search_path='' as $$
declare p text;begin
 perform pg_advisory_xact_lock(hashtextextended('kiyi-media-worker',0));
 if TG_TABLE_NAME='kiyi_posts' then
 if TG_OP='DELETE' then if old.media is not null then insert into kiyi_private.media_cleanup(path) values(old.media) on conflict do nothing;end if;return old;end if;
 if new.media is not null and exists(select 1 from kiyi_private.media_registry where path=new.media and state<>'ready') then raise exception 'Medya hazır değil.';end if;
 else
 for p in select value from jsonb_array_elements_text(coalesce(new.profile->'photos','[]')||jsonb_build_array(coalesce(new.profile->>'avatar',''),coalesce(new.profile->>'photo',''))) loop
 if exists(select 1 from kiyi_private.media_registry where path=p and state<>'ready') then raise exception 'Medya hazır değil.';end if;
 end loop;
 end if;return new;
end$$;
revoke all on function kiyi_private.stage2_media_refs() from public,anon,authenticated;
create trigger kiyi_stage2_post_media before insert or update or delete on public.kiyi_posts for each row execute function kiyi_private.stage2_media_refs();
create trigger kiyi_stage2_profile_media before insert or update on public.kiyi_profiles for each row execute function kiyi_private.stage2_media_refs();
do $$declare d text;anchor text;begin
 select pg_get_functiondef('kiyi_private.command_pre_garage(text,jsonb)'::regprocedure) into d;
 anchor:=$x$metadata->>'mimetype' in ('audio/webm','audio/mp4')$x$;
 if position(anchor in d)=0 then raise exception 'Media guard anchor missing';end if;
 execute replace(d,anchor,$x$(metadata->>'mimetype' in ('audio/webm','audio/mp4') or exists(select 1 from kiyi_private.media_registry r where r.path=payload->>'media' and r.owner=u and r.state='ready'))$x$);
end$$;
-- Bounded daily storage API cleanup. Secret lives only in a private DB table and worker memory.
select cron.schedule('kiyi-stage2-media-cleanup','17 * * * *',$cron$select net.http_post(url:='https://oswpkwwbjwyktuqcakhr.supabase.co/functions/v1/kiyi-media',headers:=jsonb_build_object('Content-Type','application/json'),body:=jsonb_build_object('action','cleanup','secret',(select secret from kiyi_private.media_worker_secret)));$cron$);
commit;
