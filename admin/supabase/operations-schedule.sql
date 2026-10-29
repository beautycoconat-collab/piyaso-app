-- Already applied as kiyi_privacy_cleanup_schedule. Do not schedule duplicates.
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('kiyi-privacy-cleanup','*/5 * * * *','select kiyi_private.ops_cleanup();');
