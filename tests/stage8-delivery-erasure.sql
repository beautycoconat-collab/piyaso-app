begin;
insert into auth.users(id,email,email_confirmed_at) values('a9999999-9999-4999-8999-999999999992','completion@example.invalid',now());
select set_config('request.jwt.claims','{"sub":"a9999999-9999-4999-8999-999999999992"}',true);
select public.kiyi_command('bundle');
select public.kiyi_command('delivery_settings','{"email":true}');
insert into public.kiyi_verifications(user_id,plate,note) values(auth.uid(),'07 SYS 001','Disposable fixture review note');
update public.kiyi_verifications set status='approved' where user_id=auth.uid();
do $$declare n int;begin
 assert exists(select 1 from public.kiyi_notifications where recipient=auth.uid() and kind='verification');
 assert exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and kind='verification');
 select count(*) into n from public.kiyi_notifications where recipient=auth.uid() and kind='verification';
 update public.kiyi_verifications set status='approved' where user_id=auth.uid();
 assert (select count(*) from public.kiyi_notifications where recipient=auth.uid() and kind='verification')=n;
end$$;
insert into kiyi_private.ops_cases(kind,owner,subject) values('privacy',auth.uid(),'delete_account');
update public.kiyi_profiles set deleted_at=now() where user_id=auth.uid();
update kiyi_private.ops_cases set status='completed' where owner=auth.uid() and kind='privacy';
do $$declare j kiyi_private.delivery_outbox;begin
 select * into j from kiyi_private.delivery_outbox where recipient=auth.uid() and kind='account_deletion';
 assert found and kiyi_private.delivery_allowed(j),'Completion notice not eligible';
 assert not exists(select 1 from kiyi_private.delivery_preferences where owner=auth.uid()),'Deleted account preferences retained';
 assert not exists(select 1 from kiyi_private.delivery_outbox where recipient=auth.uid() and kind<>'account_deletion' and state in ('waiting_configuration','queued','retry','leased'));
end$$;
select 'PASS verification notification/dedupe, opted-in completion, preference erasure, cancellation' result;
rollback;
