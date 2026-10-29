begin;
revoke all on public.kiyi_vehicle_part_products from public,anon,authenticated;
grant select on public.kiyi_vehicle_part_products to authenticated;
commit;
