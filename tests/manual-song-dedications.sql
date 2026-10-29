-- Rollback-only integration test: no real users charged or notified.
begin;
insert into auth.users(id,email) values('a4444444-4444-4444-8444-444444444441','manual-song-a@example.invalid'),('b4444444-4444-4444-8444-444444444441','manual-song-b@example.invalid');
select set_config('request.jwt.claim.sub','b4444444-4444-4444-8444-444444444441',true);
select public.kiyi_command('profile','{"searchable":true}');
select set_config('request.jwt.claim.sub','a4444444-4444-4444-8444-444444444441',true);
select public.kiyi_command('bundle');
update public.kiyi_wallets set balance=1000 where user_id=auth.uid();
set local role authenticated;
do $$ declare payload jsonb; out jsonb; denied boolean=false; begin
 payload='{"target":"b4444444-4444-4444-8444-444444444441","product":"song","request_id":"c4444444-4444-4444-8444-444444444441","song":{"source":"manual","title":"Tarkan – Kuzu Kuzu","artist":"","url":"","artwork":""}}';
 out=public.kiyi_command('gift',payload);
 perform public.kiyi_command('gift',payload);
 out=public.kiyi_command('bundle');
 assert jsonb_array_length(out->'gifts')=1,'Duplicate gift';
 assert (out->'gifts'->0->'song'->>'title')='Tarkan – Kuzu Kuzu','Song title lost';
 assert (out->>'balance')::int=1000-(out->'gifts'->0->>'credits')::int,'Duplicate charge';
 begin perform public.kiyi_command('gift',jsonb_set(jsonb_set(payload,'{request_id}',to_jsonb(gen_random_uuid()::text)),'{song,title}','"   "'));exception when raise_exception then denied=true;end;
 assert denied,'Blank title accepted';
 perform set_config('request.jwt.claim.sub','b4444444-4444-4444-8444-444444444441',true);
 out=public.kiyi_command('bundle');
 assert jsonb_array_length(out->'notifications')>=1,'Recipient notification missing';
 assert jsonb_array_length(out->'gifts')=1,'Recipient gift missing';
end $$;
rollback;
