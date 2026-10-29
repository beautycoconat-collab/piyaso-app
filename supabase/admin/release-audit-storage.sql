-- Release audit: uploads must pass authenticated kiyi-media validation.
-- The legacy permissive INSERT policy bypassed the Edge Function's byte/signature checks.
-- Service-role uploads keep working; read/delete ownership policies remain intact.
drop policy if exists kiyi_media_insert on storage.objects;
