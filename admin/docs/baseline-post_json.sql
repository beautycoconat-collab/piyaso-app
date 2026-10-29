CREATE OR REPLACE FUNCTION kiyi_private.post_json(pid uuid, viewer uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$declare p public.kiyi_posts;v jsonb;begin
 if not kiyi_private.can_post(pid,viewer) then return null;end if;select * into p from public.kiyi_posts where id=pid;v=p.poll;
 if v is not null then v=v||jsonb_build_object('counts',(select jsonb_agg((select count(*) from public.kiyi_votes where post=pid and choice=i)) from generate_series(0,jsonb_array_length(v->'options')-1) i),'vote',(select choice from public.kiyi_votes where post=pid and voter=viewer));end if;
 return to_jsonb(p)||jsonb_build_object('profile',kiyi_private.person(p.author),'mine',p.author=viewer,'poll',v,'mediaMime',case when p.media is null then null else (select metadata->>'mimetype' from storage.objects where bucket_id='kiyi-media' and name=p.media) end,'likes',(select count(*) from public.kiyi_likes where post=pid),'liked',exists(select 1 from public.kiyi_likes where post=pid and person=viewer),'comments',coalesce((select jsonb_agg(to_jsonb(c)||jsonb_build_object('profile',kiyi_private.person(c.author))) from (select * from public.kiyi_comments where post=pid and not kiyi_private.blocked(viewer,author) order by created limit 100)c),'[]'));
end $function$

