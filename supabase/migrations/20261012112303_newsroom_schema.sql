
create schema if not exists newsroom_private;
revoke all on schema newsroom_private from public;
grant usage on schema newsroom_private to authenticated;
create type public.newsroom_role as enum ('super_admin','editor','journalist','ad_manager','analyst');
create type public.article_status as enum ('draft','in_review','changes_requested','approved','scheduled','published','archived');
create table public.staff_members (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null, role public.newsroom_role not null,
 active boolean not null default true, created_at timestamptz not null default now()
);
create function newsroom_private.has_role(allowed public.newsroom_role[]) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.staff_members where user_id=auth.uid() and active and role=any(allowed))
$$;
revoke all on function newsroom_private.has_role(public.newsroom_role[]) from public;
grant execute on function newsroom_private.has_role(public.newsroom_role[]) to authenticated;
create table public.authors (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 bio text, avatar_url text, expertise text[] not null default '{}', same_as text[] not null default '{}',
 active boolean not null default true
);
create table public.categories (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 parent_id uuid references public.categories(id), description text, seo_title text, seo_description text,
 sort_order integer not null default 0, active boolean not null default true, check(parent_id is distinct from id)
);
create table public.topics (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 description text, kind text not null default 'topic' check(kind in ('topic','tag','election','state','city')),
 metadata jsonb not null default '{}'
);
create table public.media_assets (
 id uuid primary key default gen_random_uuid(), storage_path text not null unique,
 uploaded_by uuid not null default auth.uid() references auth.users(id),
 alt_text text not null default '', caption text, credit text, license text,
 mime_type text not null, width integer, height integer,
 created_at timestamptz not null default now()
);
create table public.articles (
 id uuid primary key default gen_random_uuid(), title text not null check(length(trim(title))>0),
 slug text not null unique check(slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
 subtitle text, excerpt text, body jsonb not null default '{"type":"doc","content":[]}',
 body_text text not null default '', language text not null default 'hi-Latn',
 translation_group uuid not null default gen_random_uuid(),
 author_id uuid references public.authors(id), category_id uuid references public.categories(id),
 hero_media_id uuid references public.media_assets(id),
 created_by uuid not null default auth.uid() references auth.users(id),
 status public.article_status not null default 'draft',
 scheduled_at timestamptz, published_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 version integer not null default 1,
 seo_title text, seo_description text, canonical_url text check(canonical_url is null or canonical_url ~ '^https://'),
 robots_index boolean not null default true, robots_follow boolean not null default true,
 focus_keywords text[] not null default '{}', og_title text, og_description text, og_image_url text,
 answer_summary text, key_points jsonb not null default '[]' check(jsonb_typeof(key_points)='array'),
 faqs jsonb not null default '[]' check(jsonb_typeof(faqs)='array'),
 entities jsonb not null default '[]' check(jsonb_typeof(entities)='array'),
 sources jsonb not null default '[]' check(jsonb_typeof(sources)='array'),
 dateline text, coverage_country text, coverage_state text, coverage_city text,
 article_type text not null default 'NewsArticle' check(article_type in ('NewsArticle','AnalysisNewsArticle','OpinionNewsArticle','ReportageNewsArticle')),
 correction_notice text, fact_checked_at timestamptz,
 search_vector tsvector generated always as (to_tsvector('simple',coalesce(title,'')||' '||coalesce(excerpt,'')||' '||body_text)) stored,
 check(status <> 'scheduled' or scheduled_at is not null),
 check(status <> 'published' or published_at is not null)
);
create table public.article_topics (
 article_id uuid references public.articles(id) on delete cascade, topic_id uuid references public.topics(id) on delete cascade,
 primary key(article_id,topic_id)
);
create table public.editorial_notes (
 id uuid primary key default gen_random_uuid(), article_id uuid not null references public.articles(id) on delete cascade,
 author_id uuid not null default auth.uid() references auth.users(id), note text not null,
 created_at timestamptz not null default now()
);
create table public.article_revisions (
 id bigint generated always as identity primary key, article_id uuid not null references public.articles(id) on delete cascade,
 version integer not null, snapshot jsonb not null, changed_by uuid, changed_at timestamptz not null default now(),
 unique(article_id,version)
);
create table public.audit_logs (
 id bigint generated always as identity primary key, table_name text not null, record_id text,
 action text not null, actor_id uuid, occurred_at timestamptz not null default now()
);
create table public.homepage_placements (
 id uuid primary key default gen_random_uuid(), slot text not null, position integer not null default 0,
 article_id uuid not null references public.articles(id) on delete cascade,
 starts_at timestamptz not null default now(), ends_at timestamptz,
 unique(slot,position), check(ends_at is null or ends_at>starts_at)
);
create table public.breaking_news (
 id uuid primary key default gen_random_uuid(), headline text not null,
 article_id uuid references public.articles(id) on delete set null,
 starts_at timestamptz not null default now(), ends_at timestamptz not null,
 active boolean not null default true, check(ends_at>starts_at)
);
create table public.pages (
 id uuid primary key default gen_random_uuid(), slug text not null unique, title text not null,
 body jsonb not null default '{}', published boolean not null default false,
 seo_title text, seo_description text, updated_at timestamptz not null default now()
);
create table public.site_settings (
 key text primary key, value jsonb not null, is_public boolean not null default false
);
create table public.ad_slots (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 device text not null default 'all' check(device in ('all','desktop','mobile')),
 width integer, height integer, google_slot_id text, active boolean not null default true
);
create table public.ad_campaigns (
 id uuid primary key default gen_random_uuid(), name text not null, slot_id uuid not null references public.ad_slots(id),
 image_url text not null, target_url text not null check(target_url ~ '^https://'),
 alt_text text not null, starts_at timestamptz not null, ends_at timestamptz not null,
 active boolean not null default false, sponsored_label text not null default 'Advertisement',
 check(ends_at>starts_at)
);
create table public.analytics_daily (
 day date not null, article_id uuid not null references public.articles(id) on delete cascade,
 pageviews bigint not null default 0 check(pageviews>=0),
 visitors bigint not null default 0 check(visitors>=0), source text not null,
 primary key(day,article_id,source)
);
create table public.url_redirects (
 old_slug text primary key, article_id uuid not null references public.articles(id) on delete cascade,
 created_at timestamptz not null default now()
);
create index articles_search_idx on public.articles using gin(search_vector);
create index articles_publication_idx on public.articles(status,published_at desc);
create index articles_schedule_idx on public.articles(scheduled_at) where status='scheduled';
create index articles_creator_idx on public.articles(created_by);
create index articles_category_idx on public.articles(category_id);
create index articles_author_idx on public.articles(author_id);
create index articles_media_idx on public.articles(hero_media_id);
create index articles_translation_idx on public.articles(translation_group);
create index categories_parent_idx on public.categories(parent_id);
create index media_uploader_idx on public.media_assets(uploaded_by);
create index article_topics_topic_idx on public.article_topics(topic_id);
create index notes_article_idx on public.editorial_notes(article_id);
create index notes_author_idx on public.editorial_notes(author_id);
create index homepage_article_idx on public.homepage_placements(article_id);
create index breaking_article_idx on public.breaking_news(article_id);
create index campaign_slot_idx on public.ad_campaigns(slot_id);
create index analytics_article_idx on public.analytics_daily(article_id);
create index redirects_article_idx on public.url_redirects(article_id);

do $$ declare t record; begin
for t in select tablename from pg_tables where schemaname='public' loop
execute format('alter table public.%I enable row level security',t.tablename);
execute format('revoke all on public.%I from anon, authenticated',t.tablename);
end loop; end $$;

