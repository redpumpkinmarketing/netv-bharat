
drop policy notes_read on public.editorial_notes;
drop policy notes_insert on public.editorial_notes;
drop policy revisions_read on public.article_revisions;
create policy notes_read on public.editorial_notes for select to authenticated using(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
((select newsroom_private.has_role(array['journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id and a.created_by=(select auth.uid()))));
create policy notes_insert on public.editorial_notes for insert to authenticated with check(author_id=(select auth.uid()) and (
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
((select newsroom_private.has_role(array['journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id and a.created_by=(select auth.uid())))));
create policy revisions_read on public.article_revisions for select to authenticated using(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
((select newsroom_private.has_role(array['journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id and a.created_by=(select auth.uid()))));
drop policy editorial_manage on public.site_settings;
create policy settings_manage on public.site_settings for all to authenticated using((select newsroom_private.has_role(array['super_admin']::public.newsroom_role[]))) with check((select newsroom_private.has_role(array['super_admin']::public.newsroom_role[])));
grant select on public.media_assets to anon;
create policy media_public on public.media_assets for select to anon,authenticated using(exists(select 1 from public.articles a where a.hero_media_id=media_assets.id and a.status='published' and a.published_at<=now()));
create table public.article_media (
 article_id uuid not null references public.articles(id) on delete cascade,
 media_id uuid not null references public.media_assets(id),
 position integer not null default 0, primary key(article_id,media_id)
);
alter table public.article_media enable row level security;
revoke all on public.article_media from anon,authenticated;
grant select on public.article_media to anon;
grant select,insert,update,delete on public.article_media to authenticated;
create index article_media_media_idx on public.article_media(media_id);
create policy article_media_read on public.article_media for select to anon,authenticated using(exists(select 1 from public.articles a where a.id=article_id));
create policy article_media_write on public.article_media for all to authenticated using(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
((select newsroom_private.has_role(array['journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id and a.created_by=(select auth.uid()) and a.status in ('draft','changes_requested'))))
with check(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
((select newsroom_private.has_role(array['journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id and a.created_by=(select auth.uid()) and a.status in ('draft','changes_requested'))));
drop policy media_public on public.media_assets;
create policy media_public on public.media_assets for select to anon,authenticated using(
 exists(select 1 from public.articles a where a.hero_media_id=media_assets.id and a.status='published' and a.published_at<=now()) or
 exists(select 1 from public.article_media am join public.articles a on a.id=am.article_id where am.media_id=media_assets.id and a.status='published' and a.published_at<=now()));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('newsroom-media','newsroom-media',false,15728640,array['image/jpeg','image/png','image/webp','image/avif','image/gif']);
create policy newsroom_storage_read on storage.objects for select to anon,authenticated using(bucket_id='newsroom-media' and exists(select 1 from public.media_assets m where m.storage_path=name));
create policy newsroom_storage_upload on storage.objects for insert to authenticated with check(bucket_id='newsroom-media' and (storage.foldername(name))[1]=(select auth.uid())::text and (select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])));
create policy newsroom_storage_staff_read on storage.objects for select to authenticated using(bucket_id='newsroom-media' and (select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])));
create policy newsroom_storage_delete on storage.objects for delete to authenticated using(bucket_id='newsroom-media' and (select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) and not exists(select 1 from public.media_assets m where m.storage_path=name));
create function public.search_news(search_term text, result_limit integer default 20, result_offset integer default 0)
returns table(id uuid,title text,slug text,excerpt text,language text,published_at timestamptz,rank real)
language sql stable security invoker set search_path='' as $$
select a.id,a.title,a.slug,a.excerpt,a.language,a.published_at,ts_rank(a.search_vector,websearch_to_tsquery('simple',search_term))
from public.articles a where a.status='published' and a.published_at<=now()
and a.search_vector @@ websearch_to_tsquery('simple',search_term)
order by 7 desc,a.published_at desc limit least(greatest(result_limit,1),100) offset greatest(result_offset,0)
$$;
revoke all on function public.search_news(text,integer,integer) from public;
grant execute on function public.search_news(text,integer,integer) to anon,authenticated;
create function public.save_article(p_article_id uuid,p_expected_version integer,p_title text,p_body jsonb,p_body_text text)
returns public.articles language plpgsql security invoker set search_path='' as $$
declare saved public.articles; begin
update public.articles set title=p_title,body=p_body,body_text=p_body_text
where id=p_article_id and version=p_expected_version returning * into saved;
if saved.id is null then raise exception 'Article changed or access denied; reload before saving'; end if;
return saved;
end $$;
revoke all on function public.save_article(uuid,integer,text,jsonb,text) from public,anon;
grant execute on function public.save_article(uuid,integer,text,jsonb,text) to authenticated;
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('netv_publish_scheduled','* * * * *',$job$
update public.articles set status='published',published_at=scheduled_at where status='scheduled' and scheduled_at<=now();
$job$);
insert into public.site_settings(key,value,is_public) values
('publisher','{"name":"NETV Bharat","default_content_language":"hi-Latn","timezone":"Asia/Kolkata"}',true),
('editorial_workflow','{"require_sources":true,"require_seo_description":true,"roles":["super_admin","editor","journalist","ad_manager","analyst"]}',false);

