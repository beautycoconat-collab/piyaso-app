begin;
-- Cover notification/report cleanup and the new per-subject moderation history lookup.
create index if not exists kiyi_notifications_sender on public.kiyi_notifications(sender);
create index if not exists kiyi_notifications_gift on public.kiyi_notifications(gift_id) where gift_id is not null;
create index if not exists kiyi_reports_target on public.kiyi_reports(target);
create index if not exists kiyi_reports_assignee on public.kiyi_reports(assigned_to) where assigned_to is not null;
create index if not exists kiyi_moderation_history on kiyi_private.admin_audit(entity_id,created_at desc);
alter table kiyi_private.stage6_admin_backup add column singleton boolean not null default true check(singleton),add primary key(singleton);
commit;
