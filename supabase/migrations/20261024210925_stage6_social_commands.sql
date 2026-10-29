begin;
create function kiyi_private.notification_json(note_id uuid,viewer uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare n public.kiyi_notifications;p jsonb;begin
 select * into n from public.kiyi_notifications where id=note_id and recipient=viewer;
 if not found or kiyi_private.blocked(n.sender,viewer) then return null;end if;
 if n.event_key is null then return to_jsonb(n);end if;
 p=kiyi_private.social_person(n.sender,viewer);if p is null then return null;end if;
 if n.post_id is not null and not kiyi_private.can_post(n.post_id,viewer) then return null;end if;
 if n.kind='comment' and kiyi_private.comment_json(n.comment_id,viewer) is null then return null;end if;
 if n.kind='tag' and not exists(select 1 from public.kiyi_posts where id=n.post_id and vehicle_id=n.vehicle_id) then return null;end if;
 if n.kind='badge' and n.badge_code='verified' and not exists(select 1 from public.kiyi_entitlements where user_id=viewer and verified) then return null;end if;
 return (to_jsonb(n)-'event_key')||jsonb_build_object('senderProfile',p);
end$$;
alter function kiyi_private.command(text,jsonb) rename to command_stage5;
revoke all on function kiyi_private.command_stage5(text,jsonb) from public,anon,authenticated;
create function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();r jsonb;settings jsonb;target_id uuid;pid uuid;cid uuid;subject uuid;report_id uuid;subject_type text;why text;details_text text;note jsonb;k text;
begin
 -- Preserve the existing suspension, deletion, maintenance and Auth guard.
 r=kiyi_private.command_stage5('bundle','{}');
 if jsonb_typeof(payload) is distinct from 'object' or octet_length(payload::text)>20000 then raise exception 'Geçersiz işlem.';end if;
 perform pg_advisory_xact_lock(hashtextextended('kiyi:'||u::text,0));
 if action='bundle' then
 perform kiyi_private.sync_badges(u);
 return r||jsonb_build_object('notificationSettings',coalesce((select settings from public.kiyi_social_preferences where owner=u),'{}'), 'notifications',coalesce((select jsonb_agg(q.item order by q.created desc,q.id desc) from(select n.id,n.created,kiyi_private.notification_json(n.id,u) item from public.kiyi_notifications n where recipient=u and not kiyi_private.blocked(sender,u) order by created desc,id desc limit 200)q where q.item is not null),'[]'));
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
 return jsonb_build_object('settings',coalesce((select settings from public.kiyi_social_preferences where owner=u),'{}'),'push_available',false);
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
end$$;
revoke all on function kiyi_private.notification_json(uuid,uuid) from public,anon,authenticated;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
