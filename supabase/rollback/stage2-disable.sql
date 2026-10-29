-- Operational, non-destructive rollback; retain garage/customization/media records for recovery.
-- Re-deploy the previous frontend first; then run this transaction.
-- Never run the catalog rollback while these retained garage tables reference its models.
begin;
select cron.unschedule(jobid) from cron.job where jobname='kiyi-stage2-media-cleanup';
do $$declare d text;begin
 select definition into strict d from kiyi_private.stage2_garage_backup where key='command';execute d;
 -- Old command definition restores the original public dispatcher implementation.
end$$;
revoke all on function public.kiyi_media_worker(text,jsonb) from public,anon,authenticated,service_role;
-- Keep restrictive upload gate enabled: unverified browser uploads must not resume.
-- Keep all tables, foreign keys and reference-protection triggers; no user rows are dropped.
commit;
