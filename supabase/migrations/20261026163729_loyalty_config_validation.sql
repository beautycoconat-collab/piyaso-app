begin;
-- An authorized future config edit must not leave an unclaimable NULL day.
alter table kiyi_private.reward_settings add constraint reward_calendar_values check(array_ndims(daily)=1 and array_lower(daily,1)=1 and array_position(daily,null) is null and 0<=all(daily) and 500>=all(daily));
commit;
