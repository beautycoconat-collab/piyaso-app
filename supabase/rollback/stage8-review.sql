begin;
drop trigger stage8_review_post on public.kiyi_posts;
drop trigger stage8_review_comment on public.kiyi_comments;
drop function kiyi_private.review_content();
-- Keep review records and their source for audit; no customer data is dropped.
commit;
