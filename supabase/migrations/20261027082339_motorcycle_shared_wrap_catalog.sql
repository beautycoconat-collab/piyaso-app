-- Extend the existing motorcycle wrap slot. No balances, existing prices or entitlements are modified.
insert into public.kiyi_vehicle_part_products(model_id,slot,value,sku,credits)
select m.id,'wrap',to_jsonb(w.id),'motorcycle:wrap:'||w.id,base.credits
from public.kiyi_vehicle_models m
join public.kiyi_vehicle_part_products base on base.model_id=m.id and base.slot='wrap' and base.value='"carbon"'::jsonb
cross join (values ('milk-wave'),('pink-star'),('spider-web'),('pink-kitten'),('pink-leopard'),('gold-leopard'),('retro-flower'),('race-95'),('halloween')) w(id)
where m.kind='motorcycle' and m.ready
on conflict(model_id,slot,value) do nothing;
