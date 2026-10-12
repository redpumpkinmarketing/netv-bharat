
drop policy article_update on public.articles;
create policy article_update on public.articles for update to authenticated using(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
(created_by=(select auth.uid()) and status in ('draft','changes_requested') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[])))
) with check(
(select newsroom_private.has_role(array['super_admin','editor']::public.newsroom_role[])) or
(created_by=(select auth.uid()) and status in ('draft','changes_requested','in_review') and (select newsroom_private.has_role(array['journalist']::public.newsroom_role[])))
);
insert into public.categories(name,slug,sort_order) values
('India','india',1),('Elections','elections',2),('World','world',3),('Bharat Ground','ground',4),
('Explainers','explainers',5),('Business','business',6),('Culture','culture',7),('Sports','sports',8),
('Fact Check','factcheck',9),('Visual Briefs','visual',10),('Magazine','magazine',11),('History','history',12),
('Editorial','editorial',13),('Politics','politics',14),('Cinema','cinema',15),('Books & Ideas','books',16)
on conflict(slug) do nothing;
insert into public.authors(name,slug,bio) values('NETV Bharat News Desk','netv-bharat-news-desk','The NETV Bharat editorial desk.') on conflict(slug) do nothing;

