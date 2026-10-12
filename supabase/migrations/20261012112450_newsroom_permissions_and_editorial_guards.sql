
grant select,insert,update,delete on all tables in schema public to authenticated;
revoke insert,update,delete on public.article_revisions,public.audit_logs,public.analytics_daily from authenticated;
grant usage,select on all sequences in schema public to authenticated;
grant select on public.authors,public.categories,public.topics,public.articles,public.article_topics,public.homepage_placements,public.breaking_news,public.pages,public.site_settings,public.ad_slots,public.ad_campaigns,public.url_redirects to anon;
create policy staff_read on public.staff_members for select to authenticated using(user_id=(select auth.uid()) or (select newsroom_private.has_role(array['super_admin']::public.newsroom_role[])));
create policy staff_manage on public.staff_members for all to authenticated using((select newsroom_private.has_role(array['super_admin']::public.newsroom_role[]))) with check((select newsroom_private.has_role(array['super_admin']::public.newsroom_role[])));
create policy article_public on public.articles for select to anon,authenticated using(status='published' and published_at<=now());
create policy article_staff on public.articles for select to authenticated using((select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or (created_by=(select auth.uid()) and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[]))));
create policy article_insert on public.articles for insert to authenticated with check(created_by=(select auth.uid()) and status='draft' and (select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])));
create policy article_update on public.articles for update to authenticated using(
 (select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
 (created_by=(select auth.uid()) and status in ('draft','changes_requested') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[])))
) with check(
 (select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
 (created_by=(select auth.uid()) and status in ('draft','in_review') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[])))
);
create policy article_delete on public.articles for delete to authenticated using(status='draft' and (select newsroom_private.has_role(array['super_admin']::public.newsroom_role[])));
do $$ declare t text; begin
foreach t in array array['authors','categories','topics','homepage_placements','breaking_news','pages','site_settings','url_redirects'] loop
execute format('create policy editorial_manage on public.%I for all to authenticated using ((select newsroom_private.has_role(array[''super_admin'',''editor'']::public.newsroom_role[]))) with check ((select newsroom_private.has_role(array[''super_admin'',''editor'']::public.newsroom_role[])))',t);
end loop; end $$;
create policy authors_public on public.authors for select to anon,authenticated using(active);
create policy categories_public on public.categories for select to anon,authenticated using(active);
create policy topics_public on public.topics for select to anon,authenticated using(true);
create policy homepage_public on public.homepage_placements for select to anon,authenticated using(starts_at<=now() and (ends_at is null or ends_at>now()) and exists(select 1 from public.articles a where a.id=article_id and a.status='published' and a.published_at<=now()));
create policy breaking_public on public.breaking_news for select to anon,authenticated using(active and starts_at<=now() and ends_at>now() and (article_id is null or exists(select 1 from public.articles a where a.id=article_id and a.status='published' and a.published_at<=now())));
create policy pages_public on public.pages for select to anon,authenticated using(published);
create policy settings_public on public.site_settings for select to anon,authenticated using(is_public);
create policy redirects_public on public.url_redirects for select to anon,authenticated using(exists(select 1 from public.articles a where a.id=article_id and a.status='published' and a.published_at<=now()));
create policy topics_article_read on public.article_topics for select to anon,authenticated using(exists(select 1 from public.articles a where a.id=article_id));
create policy topics_article_manage on public.article_topics for all to authenticated using(exists(select 1 from public.articles a where a.id=article_id and ((select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or (a.created_by=(select auth.uid()) and a.status in ('draft','changes_requested') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[])))))) with check(exists(select 1 from public.articles a where a.id=article_id and ((select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or (a.created_by=(select auth.uid()) and a.status in ('draft','changes_requested') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[]))))));
create policy notes_read on public.editorial_notes for select to authenticated using((select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id));
create policy notes_insert on public.editorial_notes for insert to authenticated with check(author_id=(select auth.uid()) and (select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id));
create policy revisions_read on public.article_revisions for select to authenticated using((select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])) and exists(select 1 from public.articles a where a.id=article_id));
create policy audit_read on public.audit_logs for select to authenticated using((select newsroom_private.has_role(array['super_admin']::public.newsroom_role[])));
create policy analytics_read on public.analytics_daily for select to authenticated using((select newsroom_private.has_role(array['super_admin','editor','analyst']::public.newsroom_role[])));
create policy media_read on public.media_assets for select to authenticated using((select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])));
create policy media_insert on public.media_assets for insert to authenticated with check(uploaded_by=(select auth.uid()) and (select newsroom_private.has_role(array['super_admin','editor','journalist']::public.newsroom_role[])));
create policy media_update on public.media_assets for update to authenticated using((select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[]))) with check((select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])));
do $$ declare t text; begin
foreach t in array array['ad_slots','ad_campaigns'] loop
execute format('create policy advertising_manage on public.%I for all to authenticated using ((select newsroom_private.has_role(array[''super_admin'',''ad_manager'']::public.newsroom_role[]))) with check ((select newsroom_private.has_role(array[''super_admin'',''ad_manager'']::public.newsroom_role[])))',t);
end loop; end $$;
create policy slots_public on public.ad_slots for select to anon,authenticated using(active);
create policy campaigns_public on public.ad_campaigns for select to anon,authenticated using(active and starts_at<=now() and ends_at>now() and exists(select 1 from public.ad_slots s where s.id=slot_id and s.active));
create function newsroom_private.article_guard() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if new.id<>old.id or new.created_by<>old.created_by or new.created_at<>old.created_at then raise exception 'Article identity is immutable'; end if;
  if new.slug<>old.slug and old.published_at is not null then raise exception 'Published slug is permanent; use a controlled redirect migration'; end if;
  new.version:=old.version+1;
 else new.version:=1;
 end if;
 new.updated_at:=now();
 if new.status in ('approved','scheduled','published') then
  if new.author_id is null or new.category_id is null or length(trim(new.body_text))=0 or coalesce(length(trim(new.seo_description)),0)=0 or jsonb_array_length(new.sources)=0 then
   raise exception 'Author, category, article text, SEO description and sources are required before approval';
  end if;
 end if;
 if new.status='published' then
  new.published_at:=coalesce(new.published_at,now());
  if new.published_at>now() then raise exception 'Use scheduled status for future publishing'; end if;
 end if;
 return new;
end $$;
create trigger article_guard before insert or update on public.articles for each row execute function newsroom_private.article_guard();
create function newsroom_private.record_article_revision() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.article_revisions(article_id,version,snapshot,changed_by) values(new.id,new.version,to_jsonb(new)-'search_vector',auth.uid());
 return new;
end $$;
create trigger article_revision after insert or update on public.articles for each row execute function newsroom_private.record_article_revision();
create function newsroom_private.record_audit() returns trigger language plpgsql security definer set search_path='' as $$
declare r jsonb; begin
 r:=case when tg_op='DELETE' then to_jsonb(old) else to_jsonb(new) end;
 insert into public.audit_logs(table_name,record_id,action,actor_id) values(tg_table_name,coalesce(r->>'id',r->>'user_id',r->>'key',r->>'old_slug'),tg_op,auth.uid());
 return coalesce(new,old);
end $$;
do $$ declare t text; begin
foreach t in array array['articles','staff_members','homepage_placements','breaking_news','site_settings','ad_campaigns','pages','url_redirects'] loop
execute format('create trigger audit_change after insert or update or delete on public.%I for each row execute function newsroom_private.record_audit()',t);
end loop; end $$;
revoke all on function newsroom_private.article_guard(),newsroom_private.record_article_revision(),newsroom_private.record_audit() from public,anon,authenticated;

