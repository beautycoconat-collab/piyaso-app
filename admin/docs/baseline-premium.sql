CREATE OR REPLACE FUNCTION kiyi_private.premium(u uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$select exists(select 1 from public.kiyi_entitlements where user_id=u and not suspended and premium_until>now())$function$

