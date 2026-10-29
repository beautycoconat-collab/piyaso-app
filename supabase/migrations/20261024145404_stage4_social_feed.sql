begin;
create table kiyi_private.stage4_backup(key text primary key,definition text not null);
alter table kiyi_private.stage4_backup enable row level security;
revoke all on kiyi_private.stage4_backup from public,anon,authenticated;
insert into kiyi_private.stage4_backup values('command',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure)),('post_json',pg_get_functiondef('kiyi_private.post_json(uuid,uuid)'::regprocedure)),('can_post',pg_get_functiondef('kiyi_private.can_post(uuid,uuid)'::regprocedure));
alter table public.kiyi_posts add column vehicle_id uuid references public.kiyi_vehicles(id) on delete set null,add column location_label text,add column version integer not null default 1,add column updated_at timestamptz,add column request_id uuid;
alter table public.kiyi_posts add constraint kiyi_post_general_location check(location_label is null or location_label in ('Antalya','Konyaaltı','Lara','Kültür','Bozkan','İzmir','Alsancak','Küçükpark','Bornova'));
create unique index kiyi_post_request on public.kiyi_posts(author,request_id) where request_id is not null;
create index kiyi_post_feed_cursor on public.kiyi_posts(created desc,id desc) where not hidden;
create index kiyi_post_vehicle_idx on public.kiyi_posts(vehicle_id) where vehicle_id is not null;
create function kiyi_private.social_vehicle(vid uuid,viewer uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',g.id,'owner',g.owner,'model_id',g.model_id,'name',m.name,'kind',g.kind,'plate',g.plate,'is_primary',g.is_primary,'appearance',c.appearance,'ready',m.ready,'visibility',g.visibility)
 from public.kiyi_vehicles g join public.kiyi_vehicle_models m on m.id=g.model_id join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id
 where g.id=vid and g.deleted_at is null and kiyi_private.account_active(g.owner) and (g.owner=viewer or (g.visibility='public' and not kiyi_private.blocked(g.owner,viewer) and exists(select 1 from public.kiyi_profiles where user_id=g.owner and searchable and deleted_at is null) and (kiyi_private.premium(viewer) or not exists(select 1 from public.kiyi_privacy where user_id=g.owner and ghost)) and (kiyi_private.premium(viewer) or exists(select 1 from public.kiyi_entitlements where user_id=g.owner and featured) or not exists(select 1 from public.kiyi_positions pos join public.kiyi_regions r on r.id=pos.region where pos.user_id=g.owner and r.premium))))
$$;
revoke all on function kiyi_private.social_vehicle(uuid,uuid) from public,anon,authenticated;
-- Feed/media access must not bypass existing ghost and Premium profile visibility.
create function kiyi_private.social_identity_visible(owner_id uuid,viewer uuid) returns boolean language sql stable security definer set search_path='' as $$
 select owner_id=viewer or (not kiyi_private.blocked(owner_id,viewer) and (kiyi_private.premium(viewer) or (not exists(select 1 from public.kiyi_privacy where user_id=owner_id and ghost) and (exists(select 1 from public.kiyi_entitlements where user_id=owner_id and featured) or not exists(select 1 from public.kiyi_positions pos join public.kiyi_regions r on r.id=pos.region where pos.user_id=owner_id and r.premium)))))
$$;
revoke all on function kiyi_private.social_identity_visible(uuid,uuid) from public,anon,authenticated;
alter function kiyi_private.can_post(uuid,uuid) rename to can_post_stage3;
revoke all on function kiyi_private.can_post_stage3(uuid,uuid) from public,anon,authenticated;
create function kiyi_private.can_post(pid uuid,viewer uuid) returns boolean language sql stable security definer set search_path='' as $$
 select kiyi_private.can_post_stage3(pid,viewer) and exists(select 1 from public.kiyi_posts where id=pid and kiyi_private.social_identity_visible(author,viewer))
$$;
revoke all on function kiyi_private.can_post(uuid,uuid) from public,anon,authenticated;
alter function kiyi_private.post_json(uuid,uuid) rename to post_json_stage3;
revoke all on function kiyi_private.post_json_stage3(uuid,uuid) from public,anon,authenticated;
create function kiyi_private.post_json(pid uuid,viewer uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r jsonb;v jsonb;p public.kiyi_posts;begin
 r=kiyi_private.post_json_stage3(pid,viewer);if r is null then return null;end if;
 select * into p from public.kiyi_posts where id=pid;
 v=kiyi_private.social_vehicle(p.vehicle_id,viewer);
 r=jsonb_set(r,'{comments}',coalesce((select jsonb_agg(item) from jsonb_array_elements(r->'comments') item where kiyi_private.social_identity_visible((item->>'author')::uuid,viewer)),'[]'::jsonb));
 r=(r-'vehicle_id'-'request_id')||jsonb_build_object('vehicle',v,'vehicleHidden',p.vehicle_id is not null and v is null,'commentCount',(select count(*) from public.kiyi_comments where post=pid and not hidden and kiyi_private.account_active(author) and not kiyi_private.blocked(viewer,author) and kiyi_private.social_identity_visible(author,viewer)));
 -- A public post is not a grant to expose an author's private primary-vehicle plate.
 if p.author<>viewer and not exists(select 1 from public.kiyi_vehicles g where g.owner=p.author and g.is_primary and kiyi_private.social_vehicle(g.id,viewer) is not null) then
 r=jsonb_set(r,'{profile}',(r->'profile')-'plate'-'car'-'vehicleModel'-'plateStyle'-'plateNames'-'paint');
 end if;
 return r;
end$$;
revoke all on function kiyi_private.post_json(uuid,uuid) from public,anon,authenticated;
create function kiyi_private.queue_replaced_post_media() returns trigger language plpgsql security definer set search_path='' as $$begin
 if old.media is not null and old.media is distinct from new.media then insert into kiyi_private.media_cleanup(path) values(old.media) on conflict do nothing;end if;return new;
end$$;
revoke all on function kiyi_private.queue_replaced_post_media() from public,anon,authenticated;
create trigger kiyi_replaced_post_media after update of media on public.kiyi_posts for each row execute function kiyi_private.queue_replaced_post_media();
alter function kiyi_private.command(text,jsonb) rename to command_stage3;
revoke all on function kiyi_private.command_stage3(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();p public.kiyi_posts;r jsonb;vid uuid;media text;txt text;loc text;visibility text;rid uuid;ids uuid[];pid uuid;n int;category text;result jsonb='[]';next_cursor jsonb;vehicle jsonb;
begin
 perform kiyi_private.command_stage3('bundle','{}');
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
 if (payload->>'version')::int is distinct from p.version then raise exception 'Gönderi değişmiş; yeniden yükle.' using errcode='40001';end if;
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
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;grant execute on function kiyi_private.command(text,jsonb) to authenticated;
-- Existing social table RLS and no-direct-write boundary remain in place.
commit;

