begin;
-- Preserve existing model-less legacy vehicles without relaxing ownership/privacy.
insert into kiyi_private.stage7_function_backup(name,definition) select 'social_vehicle',pg_get_functiondef('kiyi_private.social_vehicle(uuid,uuid)'::regprocedure) on conflict(name) do nothing;
create or replace function kiyi_private.social_vehicle(vid uuid,viewer uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',g.id,'owner',g.owner,'model_id',g.model_id,'name',coalesce(m.name,case when g.kind='motorcycle' then 'Motosiklet' else 'Otomobil' end),'kind',g.kind,'plate',g.plate,'is_primary',g.is_primary,'appearance',c.appearance,'ready',coalesce(m.ready,false),'visibility',g.visibility)
 from public.kiyi_vehicles g left join public.kiyi_vehicle_models m on m.id=g.model_id join public.kiyi_vehicle_customizations c on c.vehicle_id=g.id
 where g.id=vid and g.deleted_at is null and kiyi_private.account_active(g.owner) and (g.owner=viewer or (g.visibility='public' and not kiyi_private.blocked(g.owner,viewer) and exists(select 1 from public.kiyi_profiles where user_id=g.owner and searchable and deleted_at is null) and (kiyi_private.premium(viewer) or not exists(select 1 from public.kiyi_privacy where user_id=g.owner and ghost)) and (kiyi_private.premium(viewer) or exists(select 1 from public.kiyi_entitlements where user_id=g.owner and featured) or not exists(select 1 from public.kiyi_positions pos join public.kiyi_regions r on r.id=pos.region where pos.user_id=g.owner and r.premium))))
$$;
revoke all on function kiyi_private.social_vehicle(uuid,uuid) from public,anon,authenticated;
notify pgrst,'reload schema';
commit;
