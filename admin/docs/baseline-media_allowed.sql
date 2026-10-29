CREATE OR REPLACE FUNCTION kiyi_private.media_allowed(path text, viewer uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$select viewer is not null and (split_part(path,'/',1)=viewer::text or exists(select 1 from public.kiyi_posts p where p.media=path and kiyi_private.can_post(p.id,viewer)) or exists(select 1 from public.kiyi_profiles p where (p.profile->>'avatar'=path or p.profile->>'photo'=path) and (p.user_id=viewer or p.searchable) and not kiyi_private.blocked(p.user_id,viewer)))$function$

