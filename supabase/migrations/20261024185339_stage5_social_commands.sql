begin;
alter function kiyi_private.command(text,jsonb) rename to command_stage4;
revoke all on function kiyi_private.command_stage4(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();pid uuid;cid uuid;rid uuid;vid uuid;v public.kiyi_vehicles;p public.kiyi_posts;c public.kiyi_comments;txt text;r jsonb;z jsonb;results jsonb='[]';ids uuid[];n int;next_cursor jsonb;enabled boolean;ms bigint=(extract(epoch from clock_timestamp())*1000)::bigint;
begin
 perform kiyi_private.command_stage4('bundle','{}');
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
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
commit;
