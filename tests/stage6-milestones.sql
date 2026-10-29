begin;
insert into auth.users(id) values('a8888888-8888-4888-8888-888888888888');
select set_config('request.jwt.claim.sub','',true);
select set_config('request.jwt.claims','{"sub":"a8888888-8888-4888-8888-888888888888"}',true);
select public.kiyi_command('profile','{"username":"stage6_milestone"}');
insert into public.kiyi_posts(author,text,visibility,created) select 'a8888888-8888-4888-8888-888888888888','Milestone fixture '||i,'public',i from generate_series(1,10)i;
with followers as(insert into auth.users(id) select gen_random_uuid() from generate_series(1,100) returning id),profiles as(insert into public.kiyi_profiles(user_id,username) select id,'fixture_'||left(replace(id::text,'-',''),20) from followers returning user_id) insert into public.kiyi_follows(follower,target) select user_id,'a8888888-8888-4888-8888-888888888888' from profiles;
insert into public.kiyi_entitlements(user_id,verified) values('a8888888-8888-4888-8888-888888888888',true) on conflict(user_id) do update set verified=true;
set local role authenticated;
do $$declare x jsonb;begin
 x=public.kiyi_command('badges');assert x->'badges' @> '[{"code":"ten_posts"},{"code":"hundred_followers"},{"code":"verified"}]','Milestone awards';
 x=public.kiyi_command('bundle');assert (select count(*) from jsonb_array_elements(x->'notifications')n where n->>'kind'='badge' and n->>'badge_code'='ten_posts')=1,'10 posts duplicate';
end$$;
reset role;
update public.kiyi_entitlements set verified=false where user_id='a8888888-8888-4888-8888-888888888888';
set local role authenticated;
do $$declare x jsonb;begin
 x=public.kiyi_command('badges');assert not x->'badges' @> '[{"code":"verified"}]','Revoked verification still visible';
 x=public.kiyi_command('bundle');assert not x->'notifications' @> '[{"badge_code":"verified"}]','Revoked verification inbox';
end$$;
reset role;
insert into kiyi_private.social_limits(actor,kind,bucket,hits) values('a8888888-8888-4888-8888-888888888888','report',date_trunc('minute',clock_timestamp()),10) on conflict(actor,kind) do update set bucket=excluded.bucket,hits=excluded.hits;
set local role authenticated;
do $$declare bad boolean=false;begin begin perform public.kiyi_command('content_report','{"kind":"post","id":"a8888888-8888-4888-8888-888888888888","reason":"Spam"}');exception when sqlstate 'PT429' then bad=true;end;assert bad,'Report rate bypass';end$$;
reset role;
select 'PASS 10-post/100-follower/verified awards, verification revocation and report rate limit (all fixtures rolled back)' as result;
rollback;
