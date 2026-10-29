begin;
do $$begin execute(select definition from kiyi_private.stage8_backup where name='command_before_delivery');execute(select definition from kiyi_private.stage8_backup where name='health_before_delivery_retention');end$$;
drop trigger stage8_delivery_note on public.kiyi_notifications;
drop trigger stage8_delivery_verification on public.kiyi_verifications;
drop trigger stage8_delivery_case on kiyi_private.ops_cases;
update kiyi_private.ops_settings set value='false' where key in ('delivery_email_enabled','delivery_push_enabled');
revoke all on function public.kiyi_delivery_worker(text,jsonb) from service_role;
-- Preserve private queue records; coordinate with frontend rollback. Expired metadata is not restored.
commit;
