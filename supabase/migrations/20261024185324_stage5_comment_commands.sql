begin;
create or replace function kiyi_private.comment_ops(action text,payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare u uuid=auth.uid();pid uuid;cid uuid;rid uuid;vid uuid;v public.kiyi_vehicles;p public.kiyi_posts;c public.kiyi_comments;txt text;r jsonb;z jsonb;results jsonb='[]';ids uuid[];n int;next_cursor jsonb;enabled boolean;ms bigint=(extract(epoch from clock_timestamp())*1000)::bigint;
begin
 if action in ('comment_edit','comment_delete','comment_profile') then select * into c from public.kiyi_comments where id=(payload->>'comment_id')::uuid for update;pid=c.post;else pid=(payload->>'id')::uuid;end if;
 if action='comment_delete' then
 if c.id is null or not(c.author=u or exists(select 1 from public.kiyi_posts where id=pid and author=u)) then raise exception 'Yorumu silemezsin.' using errcode='42501';end if;
 perform kiyi_private.social_rate(u,'manage',60);delete from public.kiyi_comments where id=c.id;return jsonb_build_object('ok',true,'post',kiyi_private.post_json(pid,u));end if;
 if pid is null or not kiyi_private.can_post(pid,u) then raise exception 'Gönderi bulunamadı.' using errcode='42501';end if;
 if action='comment_profile' then r=kiyi_private.comment_json(c.id,u);if r is null then raise exception 'Yorum görünür değil.' using errcode='42501';end if;return jsonb_build_object('profile',r->'profile');
 elsif action='comments' then
 n=least(50,greatest(1,coalesce((payload->>'limit')::int,30)));
 select array_agg(q.id order by q.created,q.id) into ids from(select s.id,s.created from public.kiyi_comments s where s.post=pid and kiyi_private.comment_json(s.id,u) is not null and (not(payload?'cursor') or (s.created,s.id)>((payload->'cursor'->>'created')::bigint,(payload->'cursor'->>'id')::uuid)) order by s.created,s.id limit n+1)q;
 if ids is not null then foreach cid in array ids[1:n] loop results=results||jsonb_build_array(kiyi_private.comment_json(cid,u));end loop;if cardinality(ids)>n then select jsonb_build_object('created',created,'id',id) into next_cursor from public.kiyi_comments where id=ids[n];end if;end if;
 return jsonb_build_object('comments',results,'next',next_cursor,'count',(kiyi_private.post_json(pid,u)->>'commentCount')::int);
 end if;
 txt=btrim(regexp_replace(coalesce(payload->>'text',''),'[[:space:]]+',' ','g'));
 if length(txt) not between 1 and 500 then raise exception 'Yorum 1–500 karakter olmalı.';end if;
 if action='comment_edit' then
 if c.author is distinct from u or c.hidden then raise exception 'Yorumu düzenleyemezsin.' using errcode='42501';end if;
 if (payload->>'version')::int is distinct from c.version then raise sqlstate 'PT409' using message='Yorum değişmiş. Yeniden yükle.';end if;
 else
 rid=nullif(payload->>'request_id','')::uuid;
 if rid is not null then select * into c from public.kiyi_comments where author=u and request_id=rid;if found then if c.post<>pid or c.text<>txt then raise exception 'İşlem kimliği başka yorumda kullanıldı.';end if;return jsonb_build_object('post',kiyi_private.post_json(pid,u));end if;end if;
 end if;
 if exists(select 1 from public.kiyi_comments s where s.author=u and s.created>ms-60000 and lower(btrim(regexp_replace(s.text,'[[:space:]]+',' ','g')))=lower(txt) and (action='comment' or s.id<>c.id)) then raise sqlstate 'PT429' using message='Aynı yorumu tekrar göndermek için biraz bekle.';end if;
 perform kiyi_private.social_rate(u,'comment',20);
 if action='comment_edit' then update public.kiyi_comments set text=txt,version=version+1,updated_at=now() where id=c.id;
 else insert into public.kiyi_comments(post,author,text,created,request_id) values(pid,u,txt,ms,rid);end if;
 return jsonb_build_object('post',kiyi_private.post_json(pid,u));
end$$;
revoke all on function kiyi_private.comment_ops(text,jsonb) from public,anon,authenticated;
commit;
