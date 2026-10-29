-- Non-destructive rollback. Restore Sites UI v116, then run as database owner.
-- Keep added fields, posts, privacy guards, cleanup queue and safe HTTP conflicts.
begin;
do $$declare d text;begin
 select definition into strict d from kiyi_private.stage4_backup where key='command';
 execute replace(d,'''40001''','''PT409''');
end$$;
revoke all on function kiyi_private.command(text,jsonb) from public,anon;
grant execute on function kiyi_private.command(text,jsonb) to authenticated;
revoke all on function kiyi_private.post_json(uuid,uuid) from public,anon,authenticated;
revoke all on function kiyi_private.can_post(uuid,uuid) from public,anon,authenticated;
commit;
-- Forward recovery: restore only Stage 4 command function, applying PT409 fix.
-- Do not rerun ALTER/RENAME/CREATE TABLE statements on an existing installation.
