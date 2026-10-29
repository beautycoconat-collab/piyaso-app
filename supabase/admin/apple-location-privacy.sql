-- Candidate only. Apply to isolated DB first; no production deployment is implied.
begin;
create table if not exists kiyi_private.map_privacy_secret(singleton boolean primary key default true check(singleton),salt uuid not null default gen_random_uuid());
alter table kiyi_private.map_privacy_secret enable row level security;
revoke all on kiyi_private.map_privacy_secret from public,anon,authenticated,service_role;
insert into kiyi_private.map_privacy_secret(singleton)values(true)on conflict do nothing;
-- A privacy opt-in must never be overridden by a paid entitlement. Also avoid
-- returning the underlying identity in the pagination cursor for a ghost row.
do $$declare d text;begin
 d=pg_get_functiondef('kiyi_private.viewport_map(uuid,jsonb)'::regprocedure);
 if strpos(d,'case when kiyi_private.premium(viewer) or')=0 then raise exception 'Unexpected map definition';end if;
 d=replace(d,'md5(viewer::text||x.user_id::text||current_date::text)','md5((select salt::text from kiyi_private.map_privacy_secret)||viewer::text||x.user_id::text||current_date::text)');
 d=replace(d,'case when kiyi_private.premium(viewer) or','case when (kiyi_private.premium(viewer) and not x.ghost) or');
 -- Ghost rows remain approximate anonymous markers; cursor is an opaque offset
 -- into the ordered candidate set, not a user UUID. The client passes it unchanged.
 d=replace(d,'x.user_id>(p->>''after'')::uuid','md5((select salt::text from kiyi_private.map_privacy_secret)||viewer::text||x.user_id::text||current_date::text)>(p->>''after'')');
 d=replace(d,'order by x.user_id limit case when z>=17','order by md5((select salt::text from kiyi_private.map_privacy_secret)||viewer::text||x.user_id::text||current_date::text) limit case when z>=17');
 d=replace(d,'select user_id::text from chosen order by user_id desc limit 1','select md5((select salt::text from kiyi_private.map_privacy_secret)||viewer::text||user_id::text||current_date::text) from chosen order by md5((select salt::text from kiyi_private.map_privacy_secret)||viewer::text||user_id::text||current_date::text) desc limit 1');
 execute d;
end$$;
notify pgrst,'reload schema';
commit;
