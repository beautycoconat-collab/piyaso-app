-- Run after migrations in an isolated database. All rows and settings roll back.
begin;
insert into auth.users(id) values('a3333333-3333-4333-8333-333333333333'),('b3333333-3333-4333-8333-333333333333');
select set_config('request.jwt.claims','{"sub":"a3333333-3333-4333-8333-333333333333"}',true);
select public.kiyi_command('bundle');
update public.kiyi_wallets set balance=1300 where user_id='a3333333-3333-4333-8333-333333333333';
update public.kiyi_appearance set paint='#8b4cf6',plate_style='diamond' where user_id='a3333333-3333-4333-8333-333333333333';
set local role authenticated;
do $$declare x jsonb;m text;denied boolean;begin
 foreach m in array array['bmw-3','audi-a3','mercedes-c','vw-golf','renault-clio','fiat-egea','toyota-corolla'] loop
  x=public.kiyi_command('vehicle_model',jsonb_build_object('model',m));assert x->>'vehicleModel'=m,'Incorrect saved model';
  x=public.kiyi_command('bundle');assert x->'me'->>'vehicleModel'=m,'Model missing from bundle';assert x->'me'->>'paint'='#8b4cf6','Paint changed';assert x->'me'->>'plateStyle'='diamond','Plate changed';assert(x->>'balance')::int=1300,'Balance changed';assert jsonb_array_length(x->'ledger')=0,'Unexpected ledger movement';
 end loop;
 denied=false;begin perform public.kiyi_command('vehicle_model','{"model":"malicious"}');exception when invalid_parameter_value then denied=true;end;assert denied,'Invalid model accepted';
 denied=false;begin perform public.kiyi_command('vehicle_model','{}');exception when invalid_parameter_value then denied=true;end;assert denied,'Missing model accepted';
 denied=false;begin perform public.kiyi_command('vehicle_model','{"model":"bmw-3","target":"b3333333-3333-4333-8333-333333333333"}');exception when insufficient_privilege then denied=true;end;assert denied,'Cross-account edit accepted';
 denied=false;begin update public.kiyi_appearance set vehicle_model='bmw-3';exception when insufficient_privilege then denied=true;end;assert denied,'Direct appearance update permitted';
end $$;
reset role;
update public.kiyi_entitlements set suspended=true where user_id='a3333333-3333-4333-8333-333333333333';
insert into public.kiyi_entitlements(user_id,suspended) values('a3333333-3333-4333-8333-333333333333',true) on conflict(user_id) do update set suspended=true;
set local role authenticated;
do $$declare denied boolean=false;begin begin perform public.kiyi_command('vehicle_model','{"model":"bmw-3"}');exception when insufficient_privilege then denied=true;end;assert denied,'Suspended account permitted';end $$;
select set_config('request.jwt.claims','{}',true);
do $$declare denied boolean=false;begin begin perform public.kiyi_command('vehicle_model','{"model":"bmw-3"}');exception when insufficient_privilege then denied=true;end;assert denied,'Unauthenticated caller permitted';end $$;
reset role;
rollback;
