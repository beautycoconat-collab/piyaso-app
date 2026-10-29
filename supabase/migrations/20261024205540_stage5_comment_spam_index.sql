begin;
create index kiyi_comments_author_created on public.kiyi_comments(author,created desc);
commit;
