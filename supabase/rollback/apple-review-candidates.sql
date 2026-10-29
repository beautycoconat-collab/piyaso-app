-- Candidate rollback, never run automatically. Revert client UI with this SQL.
-- Retain erasure_holds and map salt as private records; do not erase legal holds.
begin;
drop function if exists public.piyaso_erasure_worker(text,jsonb);
CREATE OR REPLACE FUNCTION kiyi_private.viewport_map(viewer uuid, p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare w float8=(p->>'west')::float8;e float8=(p->>'east')::float8;s float8=(p->>'south')::float8;n float8=(p->>'north')::float8;z float8=(p->>'zoom')::float8;lim integer;result jsonb;
begin
 if w is null or e is null or s is null or n is null or z is null or not(w>=-180 and e<=180 and w<e and s>=-90 and n<=90 and s<n and z>=0 and z<=24) then raise exception 'INVALID_MAP_VIEWPORT';end if;
 lim=case when z<13 then 100 when z<15 then 200 else 400 end;
 with eligible as materialized(
 select l.*,q.ghost,r.premium from public.kiyi_positions l join public.kiyi_privacy q using(user_id) join public.kiyi_regions r on r.id=l.region
 where point(l.lng,l.lat)<@box(point(w,s),point(e,n)) and (coalesce(p->>'vehicle_kind','all')='all' or coalesce((select kind from public.kiyi_vehicles where owner=l.user_id and is_primary and deleted_at is null),'car')=p->>'vehicle_kind') and l.received_at>now()-interval '90 seconds' and (p->>'region'='all' or l.region=coalesce(p->>'region','konyaalti')) and q.sharing and r.active and kiyi_private.account_active(l.user_id) and not kiyi_private.blocked(viewer,l.user_id) and (q.visibility='all' or l.user_id=viewer or viewer=any(q.approved))
 ), counts as(select region,count(*) c from eligible group by region), totals as(select count(*) total from eligible),
 ranked as(select x.*,row_number()over(partition by x.region order by md5(x.user_id::text)) rank from eligible x),
 fair as(select user_id from ranked order by rank,region limit lim/2),
 remaining as(select x.* from ranked x where user_id not in(select user_id from fair)),
 remcounts as(select region,count(*) c from remaining group by region),
 weights as(select region,(lim-(select count(*)from fair))*c::numeric/(select count(*)from remaining) weight from remcounts),
 quotas as(select region,floor(weight)::int+case when row_number()over(order by weight-floor(weight) desc,region)<=lim-(select count(*)from fair)-(select coalesce(sum(floor(weight)),0)from weights)then 1 else 0 end quota from weights),
 remrank as(select x.*,row_number()over(partition by region order by md5(user_id::text)) nr from remaining x),
 sample as(select user_id from fair union all select x.user_id from remrank x join quotas q using(region)where nr<=q.quota),
 chosen as(select x.* from ranked x where (z>=17 and (not(p?'after') or x.user_id>(p->>'after')::uuid)) or (z<17 and ((select total from totals)<=200 or x.user_id in(select user_id from sample))) order by x.user_id limit case when z>=17 then 200 else greatest(200,lim)end)
 select jsonb_build_object('people',coalesce((select jsonb_agg(
 case when kiyi_private.premium(viewer) or (not x.premium and not x.ghost) or (not x.ghost and exists(select 1 from public.kiyi_entitlements where user_id=x.user_id and featured)) or x.user_id=viewer
 then kiyi_private.person(x.user_id) else jsonb_build_object('id',md5(viewer::text||x.user_id::text||current_date::text)::uuid,'ghost',true,'username','hayalet','plate','** ***') end ||
 jsonb_build_object('vehicleKind',coalesce((select kind from public.kiyi_vehicles where owner=x.user_id and is_primary and deleted_at is null),'car'),'pos',jsonb_build_array(case when x.user_id=viewer then x.lat else round(x.lat::numeric,2)::float8 end,case when x.user_id=viewer then x.lng else round(x.lng::numeric,2)::float8 end),'heading',case when x.user_id=viewer then x.heading else null end,'updated',extract(epoch from date_trunc('minute',x.received_at))*1000) order by x.user_id)from chosen x),'[]'),'total',(select total from totals),'sampled',z<17 and (select total from totals)>greatest(200,lim),'next',case when z>=17 and (select count(*)from chosen)=200 then (select user_id::text from chosen order by user_id desc limit 1)else null end)into result;
 return result;
end $function$
;
notify pgrst,'reload schema';
commit;
