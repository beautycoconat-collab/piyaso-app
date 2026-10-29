-- Disposable fixtures only. Always rolled back; never sends mail or notices.
begin;
do $$declare parent uuid=gen_random_uuid();child uuid;first_child uuid;vehicle uuid;model text;result jsonb;before_total bigint;plate text;begin
 select id into model from public.kiyi_vehicle_models where kind='car' order by id limit 1;
 assert model is not null;
 insert into auth.users(id,email,email_confirmed_at,created_at)values(parent,parent::text||'@example.invalid',now(),now()-interval '1 minute');
 insert into public.kiyi_profiles(user_id,username)values(parent,'rp_'||left(replace(parent::text,'-',''),20));
 perform kiyi_private.reward_identity_for(parent);
 for j in 1..7 loop
 child=gen_random_uuid();if j=1 then first_child=child;end if;
 insert into auth.users(id,email,email_confirmed_at,created_at)values(child,child::text||'@example.invalid',now(),now());
 insert into public.kiyi_profiles(user_id,username)values(child,'rp_'||left(replace(child::text,'-',''),20));
 insert into kiyi_private.reward_invites(invitee,referrer,identity_key)values(child,parent,kiyi_private.reward_identity_for(child));
 if j=1 then
 perform kiyi_private.reward_settle(parent);
 assert not exists(select 1 from kiyi_private.reward_awards where owner=parent and award_key like 'invite:%'),'No plate must not pay';
 end if;
 plate='07 TST '||(1000+j)::text;
 -- Deterministically avoid real plates; no real rows are changed.
 while exists(select 1 from kiyi_private.reward_vehicle_plates where plate_hash=md5(regexp_replace(plate,'[^A-Z0-9]','','g')))
 loop plate='07 TST '||((random()*90000)::int+10000)::text;end loop;
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(child,model,'car',plate)returning id into vehicle;
 if j=1 then
 assert kiyi_private.reward_invite_plate(child) is not null;
 assert not exists(select 1 from kiyi_private.reward_days where owner=child),'No activity day fixtures';
 perform kiyi_private.reward_settle(parent);perform kiyi_private.reward_settle(parent);
 assert(select sum(amount)from kiyi_private.reward_awards where owner=parent and award_key like 'invite:%')=75,'Plate qualifies without 3 days, once only';
 assert(select balance from public.kiyi_wallets where user_id=parent)=75;
 update public.kiyi_vehicles set deleted_at=now() where id=vehicle;
 assert kiyi_private.reward_invite_plate(child) is null,'Deleted vehicle does not qualify';
 update public.kiyi_vehicles set deleted_at=null where id=vehicle;
 perform kiyi_private.reward_settle(parent);
 assert(select balance from public.kiyi_wallets where user_id=parent)=75,'Re-add must not replay';
 elsif j=7 then
 insert into kiyi_private.badge_invalidations(kind,subject,actor,reason)values('invite',child,parent,'Disposable invalidation test');
 end if;
 end loop;
 perform kiyi_private.reward_process_invites();perform kiyi_private.reward_process_invites();
 assert(select sum(amount)from kiyi_private.reward_awards where owner=parent and award_key like 'invite:%')=375,'Monthly cap stays five';
 assert(select count(*)from kiyi_private.reward_invites where referrer=parent and paid_at is not null)=5;
 -- A previously rewarded plate cannot be re-used by another invitee after deletion.
 select v.plate into plate from public.kiyi_vehicles v where v.owner=first_child limit 1;
 update public.kiyi_vehicles set deleted_at=now(),plate='07 OLD 81927' where owner=first_child;
 child=gen_random_uuid();insert into auth.users(id,email,email_confirmed_at)values(child,child::text||'@example.invalid',now());
 insert into public.kiyi_profiles(user_id,username)values(child,'rp_'||left(replace(child::text,'-',''),20));
 insert into public.kiyi_vehicles(owner,model_id,kind,plate)values(child,model,'car',plate);
 assert kiyi_private.reward_invite_plate(child) is null,'Plate cycling must not qualify';
 assert not has_function_privilege('authenticated','kiyi_private.reward_invite_plate(uuid)','execute');
 assert not has_function_privilege('authenticated','kiyi_private.reward_settle(uuid)','execute');
 assert not has_table_privilege('authenticated','kiyi_private.reward_invite_plates','insert');
 assert(select relrowsecurity from pg_class where oid='kiyi_private.reward_invite_plates'::regclass);
 assert(select referral_amount from kiyi_private.reward_settings)=75;
 assert(select sum(n)from kiyi_private.reward_settings,unnest(daily)n)=320;
end$$;
rollback;
select 'PASS plate qualification, deleted/reused plate, idempotency, monthly cap, private access and existing amounts' result;
