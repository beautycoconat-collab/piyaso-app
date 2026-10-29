begin;
revoke all on public.kiyi_vehicle_models,public.kiyi_vehicle_parts from public,anon,authenticated;
grant select on public.kiyi_vehicle_models,public.kiyi_vehicle_parts to authenticated;
commit;
