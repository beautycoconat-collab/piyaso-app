begin;
create or replace function kiyi_private.command(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
 return result||jsonb_build_object('level_badges',coalesce((select jsonb_agg(jsonb_build_object('code',b.code,'earned_at',b.earned_at,'title',c.title,'level',c.level,'image',c.image)order by c.position)from kiyi_private.badge_earned b join kiyi_private.badge_catalog c on c.code=b.code where b.owner=t and b.active and ((c.level is null and c.code not in('verified','premium_member')) or (coalesce((metrics->>c.metric)::int,0)>=c.threshold and (c.code<>'map_ultra' or (metrics->>'map_regions')::int=3)))),'[]'));
 end if;return result;
end$$;
commit;

