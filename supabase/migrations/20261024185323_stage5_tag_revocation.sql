begin;
create function kiyi_private.revoke_plate_tags() returns trigger language plpgsql security definer set search_path='' as $$begin
 if TG_TABLE_NAME='kiyi_privacy' then
 if old.allow_plate_tags and not new.allow_plate_tags then update public.kiyi_posts p set vehicle_id=null,version=p.version+1,updated_at=now() from public.kiyi_vehicles v where p.vehicle_id=v.id and v.owner=new.user_id and p.author<>v.owner;end if;
 elsif TG_TABLE_NAME='kiyi_vehicles' then
 if new.visibility<>'public' or new.deleted_at is not null or new.plate_key is distinct from old.plate_key or new.owner is distinct from old.owner then update public.kiyi_posts set vehicle_id=null,version=version+1,updated_at=now() where vehicle_id=new.id and author<>new.owner;end if;
 else
 update public.kiyi_posts p set vehicle_id=null,version=p.version+1,updated_at=now() from public.kiyi_vehicles v where p.vehicle_id=v.id and ((p.author=new.owner and v.owner=new.target) or (p.author=new.target and v.owner=new.owner));
 end if;return new;
end$$;
revoke all on function kiyi_private.revoke_plate_tags() from public,anon,authenticated;
create trigger kiyi_consent_tag_revoke after update of allow_plate_tags on public.kiyi_privacy for each row execute function kiyi_private.revoke_plate_tags();
create trigger kiyi_vehicle_tag_revoke after update of visibility,deleted_at,plate,owner on public.kiyi_vehicles for each row execute function kiyi_private.revoke_plate_tags();
create trigger kiyi_block_tag_revoke after insert on public.kiyi_blocks for each row execute function kiyi_private.revoke_plate_tags();
alter function kiyi_private.post_json(uuid,uuid) rename to post_json_stage4;
revoke all on function kiyi_private.post_json_stage4(uuid,uuid) from public,anon,authenticated;
create function kiyi_private.post_json(pid uuid,viewer uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r jsonb;v public.kiyi_vehicles;p public.kiyi_posts;begin
 r=kiyi_private.post_json_stage4(pid,viewer);if r is null then return null;end if;
 select * into p from public.kiyi_posts where id=pid;select * into v from public.kiyi_vehicles where id=p.vehicle_id;
 if v.owner<>p.author and not coalesce((select allow_plate_tags from public.kiyi_privacy where user_id=v.owner),false) then r=r||jsonb_build_object('vehicle',null,'vehicleHidden',true);end if;
 return r||jsonb_build_object('following',exists(select 1 from public.kiyi_follows where follower=viewer and target=p.author),'canUntag',p.vehicle_id is not null and (p.author=viewer or v.owner=viewer),'comments',coalesce((select jsonb_agg(q.data order by q.created,q.id) from(select c.id,c.created,kiyi_private.comment_json(c.id,viewer) as data from public.kiyi_comments c where c.post=pid and kiyi_private.comment_json(c.id,viewer) is not null order by c.created,c.id limit 100)q),'[]'));
end$$;
revoke all on function kiyi_private.post_json(uuid,uuid) from public,anon,authenticated;
commit;
