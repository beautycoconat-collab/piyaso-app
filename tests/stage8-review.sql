begin;
insert into auth.users(id) values('a8888888-8888-4888-8888-888888888882');
select set_config('request.jwt.claims','{"sub":"a8888888-8888-4888-8888-888888888882"}',true);
select public.kiyi_command('bundle');
do $$declare p uuid;begin
 insert into public.kiyi_posts(author,text,visibility,created) values(auth.uid(),'seni öldüreceğim','public',1) returning id into p;
 assert (select count(*) from public.kiyi_reports where subject_id=p and source='automated')=1,'Missing auto review';
 update public.kiyi_posts set text='seni öldüreceğim tekrar' where id=p;
 assert (select count(*) from public.kiyi_reports where subject_id=p and source='automated')=1,'Duplicate auto review';
 assert not (select hidden from public.kiyi_posts where id=p),'Classifier made final decision';
end$$;
select 'PASS conservative automatic review, durable queue, deduplication, no automatic final verdict' result;
rollback;
