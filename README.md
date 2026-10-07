# NETV Bharat

Minimalist NETV Bharat newsroom frontend, maintained by Red Pumpkin Marketing.

## Status
Frontend staging release. Sample articles, reserved ad slots and draft policies are intentionally labelled. CMS, database, admin login, live election data, analytics and ad serving are not connected yet. Search indexing is disabled until editorial launch.

## Structure
- `dist/`: complete editable HTML, CSS, JavaScript and original image assets; also the upload-ready website.
- `checks/frontend.mjs`: frontend interaction checks.
- `package.json` and lockfile: local development dependencies.

## Local development
Use Node.js compatible with the Vite version in the lockfile.

```sh
npm ci
npm run dev
node checks/frontend.mjs
```

## Upload to Hostinger or another static host
Back up the existing website first. Copy the **contents of dist/** into the selected domain's document root (usually `public_html/`). The resulting path must be `public_html/index.html`, not `public_html/dist/index.html`.

No server-side Node process or build is required. Assets use domain-root URLs, so deploy at the domain root. Use HTTPS. Fonts request Google Fonts and include fallback fonts. Do not upload node_modules or development configuration to the public root.

This repository upload alone does not enable GitHub Pages or configure hosting.

## Verification
50 linked routes, 8 policy pages, search, state filtering, menu interactions, language reset, keyboard focus, internal anchors and asset checks passed. JavaScript syntax checks passed. Actual browser visual verification remains pending; responsive CSS was reviewed.

After hosting, check 320, 390, 768, 1024 and 1440px widths, navigation, search, footer, article refresh and copy-link behavior over HTTPS.

## Backend phase
Connect a CMS/database with editorial roles, article publishing, language editions, state/category mapping, media uploads, ad management and analytics. Add crawlable article/language routes and article metadata. Finalize real content, publisher/contact details and policies before removing noindex. Noindex is not access control; use hosting access protection for private staging.
