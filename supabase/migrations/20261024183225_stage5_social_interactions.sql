begin;
create table kiyi_private.stage5_backup(key text primary key,definition text not null);
alter table kiyi_private.stage5_backup enable row level security;
revoke all on kiyi_private.stage5_backup from public,anon,authenticated;
insert into kiyi_private.stage5_backup values('command',pg_get_functiondef('kiyi_private.command(text,jsonb)'::regprocedure)),('post_json',pg_get_functiondef('kiyi_private.post_json(uuid,uuid)'::regprocedure));
alter table public.kiyi_privacy add column allow_plate_tags boolean not null default false;
alter table public.kiyi_comments add column version integer not null default 1,add column updated_at timestamptz,add column request_id uuid;
create unique index kiyi_comment_request on public.kiyi_comments(author,request_id) where request_id is not null;
create index kiyi_comment_cursor on public.kiyi_comments(post,created,id) where not hidden;
create table kiyi_private.social_limits(actor uuid references auth.users on delete cascade,kind text,bucket timestamptz not null,hits int not null,primary key(actor,kind));
alter table kiyi_private.social_limits enable row level security;
revoke all on kiyi_private.social_limits from public,anon,authenticated;
create function kiyi_private.social_rate(u uuid,k text,n int) returns void language plpgsql security definer set search_path='' as $$
declare h int;b timestamptz=date_trunc('minute',clock_timestamp());begin
 insert into kiyi_private.social_limits as l values(u,k,b,1) on conflict(actor,kind) do update set bucket=b,hits=case when l.bucket=b then l.hits+1 else 1 end returning hits into h;
 if h>n then raise sqlstate 'PT429' using message='Çok hızlı işlem yapıyorsun. Bir dakika sonra yeniden dene.';end if;
end$$;
revoke all on function kiyi_private.social_rate(uuid,text,int) from public,anon,authenticated;
create function kiyi_private.social_person(person_id uuid,viewer uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r jsonb;begin
 if not kiyi_private.social_identity_visible(person_id,viewer) or not kiyi_private.account_active(person_id) then return null;end if;
 r=kiyi_private.person(person_id);
 if person_id<>viewer and not exists(select 1 from public.kiyi_vehicles g where g.owner=person_id and g.is_primary and kiyi_private.social_vehicle(g.id,viewer) is not null) then r=r-'plate'-'car'-'vehicleModel'-'plateStyle'-'plateNames'-'paint';end if;
 return r;
end$$;
revoke all on function kiyi_private.social_person(uuid,uuid) from public,anon,authenticated;
create function kiyi_private.comment_json(cid uuid,viewer uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select (to_jsonb(c)-'request_id')||jsonb_build_object('profile',kiyi_private.social_person(c.author,viewer),'mine',c.author=viewer,'canEdit',c.author=viewer,'canDelete',c.author=viewer or p.author=viewer)
 from public.kiyi_comments c join public.kiyi_posts p on p.id=c.post where c.id=cid and not c.hidden and kiyi_private.can_post(c.post,viewer) and not kiyi_private.blocked(viewer,c.author) and kiyi_private.social_person(c.author,viewer) is not null
$$;
revoke all on function kiyi_private.comment_json(uuid,uuid) from public,anon,authenticated;
-- Revocation is durable: an old tag does not reappear after re-enabling consent.
commit;
