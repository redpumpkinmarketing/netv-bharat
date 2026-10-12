# NETV Bharat — connected newsroom

Vite frontend with a Supabase newsroom backend. `/admin` opens the staff login; public pages query published stories instead of local samples. The original static sample data remains in `src/data/stories.js` for historical reference and is not imported at runtime.

## Run and deploy

```sh
npm ci
npm test
npm run build
```

Hostinger: root `./`, build `npm run build`, output `dist`. The complete build is committed for file-manager hosting too. Deploy **all contents** of `dist`, including `.htaccess`, to the website root. Direct routes `/admin` and `/article/<slug>` need the included Apache rewrite rules. Deploying GitHub or linking Supabase to GitHub alone does not update an existing Hostinger file-manager upload.

The client uses the NETV Bharat project `ajaqpncrdedpeokircud` and its **publishable** key. The key is intentionally public; access is controlled by database RLS. No database password or service-role secret belongs in frontend code.

## Admin

- Individual staff login, sign out, password recovery.
- Super Admin: staff accounts and permissions, settings, editorial tools, ads, activity log.
- Editor: articles and publishing, authors, categories, topics, homepage, breaking news, pages, media.
- Journalist: own drafts, revisions and notes; submit for review. Cannot approve or publish.
- Ad Manager: advertising slots and campaigns.
- Analyst: real imported analytics only.

The owner account is already assigned in the database. Use the password entered in Supabase Auth. Account passwords are not included in this repository.

The `newsroom-team` Edge Function is deployed separately in Supabase. It validates the caller's token using Auth and checks the current active Super Admin database role before creating a staff account. Gateway JWT verification is disabled **only because the function performs this validation itself**. Source is tracked in `supabase/functions/newsroom-team/index.ts`.

For password-recovery emails, add the real `https://YOUR-DOMAIN/admin` to Supabase Authentication URL Configuration and set the Site URL. Configure production SMTP for reliable delivery. Never use a site-preview URL as the permanent production redirect.

## Publishing

Create a draft, save it, submit for review, approve, then publish or schedule. Author, category, body, SEO description and sources are required before approval. Slugs accept lowercase Latin characters and remain permanent after publication. For Hindi/Bengali headlines, enter a transliterated slug. Draft autosave runs after 30 seconds of inactivity; version checks prevent overwriting a concurrent update. Images must have alt text, credit and usage rights. Media is private until linked to a published story.

Metadata includes title, description, canonical override, indexing, social previews, answer summary, key points, FAQs, named entities, citations and geographic coverage. The public article renders source links, FAQs, correction notes and JSON-LD. Only actually published language editions are shown; switching language does not machine-translate a story.

## Important boundaries

- This remains a client-rendered Vite site. Metadata and JSON-LD are rendered in JavaScript. Reliable initial-HTML article metadata for non-JavaScript social crawlers, server-generated sitemaps, and full server rendering require a subsequent hosting/rendering integration. Do not claim SSR or universal rich-preview support from this build.
- The article editor currently uses safe plain-text paragraphs, plus a cover image; a rich-text formatting toolbar and inline media editor are not included.
- Manual image advertising is supported. Google AdSense requires the publisher account and slot configuration before script integration.
- Analytics displays `analytics_daily` data when a real data importer is connected; no tracking or importer is installed yet.
- Election categories/topics support editorial coverage, not live counting feeds.
- Backups/restoration and production email delivery must be configured against the selected Supabase plan.
- Published database pages override bundled policy text. Review and publish your final legal/editorial copy before public launch.

## Database source

`supabase/migrations/` contains the migrations already applied to NETV Bharat, exported with their actual remote versions. Do not rerun them as raw SQL against this existing project. They support version control and rebuilding a separate environment. The owner Auth user and private setup settings are not seeded here.

## Verification

`npm test` uses DOM fixtures to verify login, role-aware navigation, editor fields, safe previews, public article rendering, metadata and empty states. The production build and real anonymous Supabase API access were also checked. No real staff password is used in tests. This is not a completed production browser/end-to-end publication check.
