CREATE OR REPLACE FUNCTION kiyi_private.person(u uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
select (p.profile-'verified'-'premium'-'plateStyle'-'plateNames'-'paint'-'avatarFrame')||jsonb_build_object('id',p.user_id,'username',p.username,'searchable',p.searchable,'verified',coalesce(e.verified,false),'plateStyle',coalesce(a.plate_style,'classic'),'plateNames',coalesce(a.plate_names,'{}'),'paint',coalesce(a.paint,'#ffffff'),'avatarFrame',coalesce(a.frame,'none'),'serverProfile',true,'supabaseProfile',true,'publicProfile',true,'sharing',false,'featured',false,'online',exists(select 1 from public.kiyi_positions l where l.user_id=u and l.received_at>now()-interval '90 seconds')) from public.kiyi_profiles p left join public.kiyi_appearance a on a.user_id=p.user_id left join public.kiyi_entitlements e on e.user_id=p.user_id where p.user_id=u and not coalesce(e.suspended,false)
$function$

