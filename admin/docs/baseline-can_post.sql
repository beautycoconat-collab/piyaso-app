CREATE OR REPLACE FUNCTION kiyi_private.can_post(pid uuid, viewer uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$select exists(select 1 from public.kiyi_posts p where p.id=pid and not kiyi_private.blocked(viewer,p.author) and (p.author=viewer or p.visibility='public' or exists(select 1 from public.kiyi_follows f where f.follower=viewer and f.target=p.author)))$function$

