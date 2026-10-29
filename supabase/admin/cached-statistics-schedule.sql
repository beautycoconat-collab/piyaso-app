select kiyi_private.ops_refresh_statistics();
select cron.schedule('kiyi-statistics-refresh','*/5 * * * *','select kiyi_private.ops_refresh_statistics();');
