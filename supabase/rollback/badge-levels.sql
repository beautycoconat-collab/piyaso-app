begin;
-- Retain awards, map-day facts and wallets. Stop only the new computation hooks.
drop trigger if exists badge_map_event on public.kiyi_positions;
drop trigger if exists badge_privacy_event on public.kiyi_privacy;
do $$declare definition text;begin select b.definition into definition from kiyi_private.badge_backup b where name='command';if definition is null then raise exception 'Missing dispatcher backup';end if;execute definition;end$$;
-- Account-erasure cleanup stays enabled. Existing badges and all coin balances stay untouched.
commit;
