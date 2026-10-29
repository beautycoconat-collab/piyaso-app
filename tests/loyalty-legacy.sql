-- Inject this fixture before the migration to verify a real pre-existing account transition.
begin;
create temp table loyalty_legacy_fixture(id uuid default gen_random_uuid());insert into loyalty_legacy_fixture default values;
insert into auth.users(id,email,created_at)select id,id::text||'@example.invalid',now()-interval '1 day'from loyalty_legacy_fixture;
select set_config('request.jwt.claims',jsonb_build_object('sub',id)::text,true)from loyalty_legacy_fixture;select public.kiyi_command('bundle');
insert into public.kiyi_badges(owner,code)select id,'first_post'from loyalty_legacy_fixture;
update public.kiyi_profiles set profile='{"ownerName":"Eski Kullanıcı","bio":"Mevcut tamamlanmış profil açıklaması","avatar":"https://example.invalid/avatar.jpg"}'where user_id=auth.uid();
-- MIGRATION HERE
update auth.users set email_confirmed_at=now()where id=auth.uid();
select public.kiyi_command('rewards');
do $$begin
 assert (select balance from public.kiyi_wallets where user_id=auth.uid())=0;
 assert exists(select 1 from kiyi_private.reward_awards where owner=auth.uid()and award_key='achievement:profile_complete'and legacy and amount=0);
 assert exists(select 1 from public.kiyi_badges where owner=auth.uid()and code='first_post');
 -- Existing badge remains consumed even when the historical post was removed before migration.
 perform kiyi_private.reward_sync(auth.uid());assert (select balance from public.kiyi_wallets where user_id=auth.uid())=0;
end$$;
select 'PASS prior unverified profile, preserved badge, no retrospective credits' result;rollback;
