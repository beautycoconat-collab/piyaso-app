begin;
-- Retain paid awards and consumed plate records; never subtract earned coins.
do $$declare r record;begin for r in select definition from kiyi_private.reward_backup where name like 'plate_v1:%' loop execute r.definition;end loop;end$$;
commit;
