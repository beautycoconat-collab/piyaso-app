-- Normal rollback: publish UI version 118; additive DB remains backward-compatible.
-- Optional command rollback below preserves records, consent and revocation triggers.
-- Editing an existing foreign tag then requires Stage 5 to be restored.
begin;
do $$declare d text;begin
 select definition into strict d from kiyi_private.stage5_backup where key='command';execute d;
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
commit;
-- Keep the safe serializer, consent triggers, comment columns and unlike alias fix.
-- Forward recovery: restore CREATE OR REPLACE command from stage5_social_commands.
