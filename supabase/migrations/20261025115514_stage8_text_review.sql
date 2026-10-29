begin;
alter table public.kiyi_reports add column source text not null default 'user' check(source in ('user','automated'));
create function kiyi_private.review_content() returns trigger language plpgsql security definer set search_path='' as $$
declare kind text=case when tg_table_name='kiyi_posts' then 'post' else 'comment' end;why text;
begin
 if new.hidden then return new;end if;
 if tg_op='UPDATE' and new.text is not distinct from old.text and to_jsonb(new)->'media' is not distinct from to_jsonb(old)->'media' then return new;end if;
 if lower(new.text) ~ '(seni|sizi)[[:space:]]+(öldür|oldur)' then why='Olası tehdit';
 elsif new.text ~ '0?5[0-9]{2}[[:space:]-]*[0-9]{3}[[:space:]-]*[0-9]{2}[[:space:]-]*[0-9]{2}' then why='Olası kişisel bilgi ifşası';
 elsif length(new.text)-length(replace(new.text,'https://',''))>40 then why='Olası bağlantı spamı';
 elsif kind='post' and nullif(to_jsonb(new)->>'media','') is not null then why='Görsel/video otomatik sınıflandırıcısı bağlı değil; insan incelemesi gerekli';
 else return new;end if;
 if not exists(select 1 from public.kiyi_reports where source='automated' and subject_kind=kind and subject_id=new.id and status in ('pending','in_review')) then
 -- reporter is the record owner, NOT a claim that the author filed a complaint.
 insert into public.kiyi_reports(reporter,target,reason,details,subject_kind,subject_id,source) values(new.author,new.author,'Diğer','OTOMATİK İNCELEME — kullanıcı şikâyeti değildir. '||why,kind,new.id,'automated');
 end if;return new;
end$$;
revoke all on function kiyi_private.review_content() from public,anon,authenticated;
create trigger stage8_review_post after insert or update on public.kiyi_posts for each row execute function kiyi_private.review_content();
create trigger stage8_review_comment after insert or update on public.kiyi_comments for each row execute function kiyi_private.review_content();
notify pgrst,'reload schema';
commit;
