begin;
do $$declare denied bool=false;begin
 begin update kiyi_private.reward_settings set daily[1]=null;exception when check_violation then denied=true;end;assert denied;
 denied=false;begin update kiyi_private.reward_settings set daily[1]=-1;exception when check_violation then denied=true;end;assert denied;
 denied=false;begin update kiyi_private.reward_settings set daily[1]=501;exception when check_violation then denied=true;end;assert denied;
 assert (select sum(x)from kiyi_private.reward_settings,unnest(daily)x)=320;
end$$;select 'PASS null/negative/oversized config rejected without calendar change' result;rollback;
