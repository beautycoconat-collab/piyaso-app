begin;
create table public.kiyi_badges(owner uuid not null references auth.users on delete cascade,code text not null check(code in ('first_vehicle','first_post','ten_posts','hundred_followers','verified')),earned_at timestamptz not null default now(),primary key(owner,code));
create table public.kiyi_social_preferences(owner uuid primary key references auth.users on delete cascade,settings jsonb not null default '{}' check(jsonb_typeof(settings)='object' and octet_length(settings::text)<500));
alter table public.kiyi_badges enable row level security;
alter table public.kiyi_social_preferences enable row level security;
revoke all on public.kiyi_badges,public.kiyi_social_preferences from public,anon,authenticated;
alter table public.kiyi_notifications add column post_id uuid references public.kiyi_posts on delete cascade,add column comment_id uuid references public.kiyi_comments on delete cascade,add column vehicle_id uuid references public.kiyi_vehicles on delete cascade,add column badge_code text,add column event_key text;
create unique index kiyi_notification_event on public.kiyi_notifications(recipient,event_key) where event_key is not null;
create index kiyi_notification_post on public.kiyi_notifications(post_id) where post_id is not null;
create index kiyi_notification_comment on public.kiyi_notifications(comment_id) where comment_id is not null;
create index kiyi_notification_vehicle on public.kiyi_notifications(vehicle_id) where vehicle_id is not null;
alter table public.kiyi_reports add column subject_kind text check(subject_kind in ('post','comment')),add column subject_id uuid;
create index kiyi_reports_subject on public.kiyi_reports(reporter,subject_kind,subject_id,created_at desc);
create function kiyi_private.social_notify(recipient_id uuid,actor_id uuid,event_type text,event_id text,pid uuid default null,cid uuid default null,vid uuid default null,badge text default null) returns void language plpgsql security definer set search_path='' as $$
begin
 if event_type not in ('follow','like','comment','tag','badge') or recipient_id is null or actor_id is null or (recipient_id=actor_id and event_type<>'badge') or kiyi_private.blocked(recipient_id,actor_id) or not kiyi_private.account_active(recipient_id) then return;end if;
 if coalesce((select (settings->>event_type)::boolean from public.kiyi_social_preferences where owner=recipient_id),true)=false then return;end if;
 insert into public.kiyi_notifications(recipient,sender,kind,created,post_id,comment_id,vehicle_id,badge_code,event_key) values(recipient_id,actor_id,event_type,(extract(epoch from clock_timestamp())*1000)::bigint,pid,cid,vid,badge,event_type||':'||event_id) on conflict(recipient,event_key) where event_key is not null do nothing;
end$$;
create function kiyi_private.sync_badges(person_id uuid,notify boolean default true) returns void language plpgsql security definer set search_path='' as $$
declare codes text[]='{}';code_id text;new_code text;posts_count int;
begin
 if not kiyi_private.account_active(person_id) then return;end if;
 if exists(select 1 from public.kiyi_vehicles where owner=person_id and deleted_at is null and (model_id is not null or plate_key is not null)) then codes=array_append(codes,'first_vehicle');end if;
 select count(*) into posts_count from (select 1 from public.kiyi_posts where author=person_id and not hidden limit 10)x;
 if posts_count>=1 then codes=array_append(codes,'first_post');end if;if posts_count>=10 then codes=array_append(codes,'ten_posts');end if;
 if (select count(*) from (select 1 from public.kiyi_follows f where target=person_id and kiyi_private.account_active(follower) and not kiyi_private.blocked(follower,target) limit 100)x)>=100 then codes=array_append(codes,'hundred_followers');end if;
 if exists(select 1 from public.kiyi_entitlements where user_id=person_id and verified) then codes=array_append(codes,'verified');end if;
 foreach code_id in array codes loop
 new_code=null;insert into public.kiyi_badges(owner,code) values(person_id,code_id) on conflict do nothing returning code into new_code;
 if new_code is not null and notify then perform kiyi_private.social_notify(person_id,person_id,'badge',code_id,null,null,null,code_id);end if;
 end loop;
end$$;
create function kiyi_private.social_event() returns trigger language plpgsql security definer set search_path='' as $$
declare owner_id uuid;begin
 if tg_table_name='kiyi_follows' then
 perform kiyi_private.social_notify(new.target,new.follower,'follow',new.follower::text);perform kiyi_private.sync_badges(new.target);
 elsif tg_table_name='kiyi_likes' then
 select author into owner_id from public.kiyi_posts where id=new.post;
 perform kiyi_private.social_notify(owner_id,new.person,'like',new.person::text||':'||new.post::text,new.post);
 elsif tg_table_name='kiyi_comments' then
 select author into owner_id from public.kiyi_posts where id=new.post;
 perform kiyi_private.social_notify(owner_id,new.author,'comment',new.id::text,new.post,new.id);
 elsif tg_table_name='kiyi_posts' then
 if tg_op='INSERT' then perform kiyi_private.sync_badges(new.author);end if;
 if new.vehicle_id is not null then
 select owner into owner_id from public.kiyi_vehicles where id=new.vehicle_id;
 perform kiyi_private.social_notify(owner_id,new.author,'tag',new.id::text||':'||new.vehicle_id::text,new.id,null,new.vehicle_id);
 end if;
 elsif tg_table_name='kiyi_vehicles' then perform kiyi_private.sync_badges(new.owner);
 elsif tg_table_name='kiyi_entitlements' then perform kiyi_private.sync_badges(new.user_id);
 end if;return new;
end$$;
create trigger stage6_follow after insert on public.kiyi_follows for each row execute function kiyi_private.social_event();
create trigger stage6_like after insert on public.kiyi_likes for each row execute function kiyi_private.social_event();
create trigger stage6_comment after insert on public.kiyi_comments for each row execute function kiyi_private.social_event();
create trigger stage6_post after insert or update of vehicle_id on public.kiyi_posts for each row execute function kiyi_private.social_event();
create trigger stage6_vehicle after insert or update of model_id,plate on public.kiyi_vehicles for each row execute function kiyi_private.social_event();
create trigger stage6_entitlement after insert or update of verified on public.kiyi_entitlements for each row execute function kiyi_private.social_event();
-- Existing achievements are backfilled without replaying historical notifications.
select kiyi_private.sync_badges(user_id,false) from public.kiyi_profiles where deleted_at is null;
revoke all on function kiyi_private.social_notify(uuid,uuid,text,text,uuid,uuid,uuid,text),kiyi_private.sync_badges(uuid,boolean),kiyi_private.social_event() from public,anon,authenticated;
commit;
