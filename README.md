# NETV Bharat

NETV Bharat newsroom frontend, maintained by Red Pumpkin Marketing.

## Architecture
The frontend now uses clean History API routes such as `/elections`, `/india` and `/article/cities` instead of hash URLs. Vite is the production build system and Apache/Hostinger fallback rules route direct requests back to `index.html`.

Source code lives in:
- `src/main.js` — application UI, route rendering and interactions
- `src/data/stories.js` — temporary editorial data layer
- `src/policies.js` — policy/editorial information pages
- `src/style.css` — responsive design system
- `index.html` — application shell

The current data layer is intentionally local/mock. It is separated so the next phase can replace it with a CMS/API/database without redesigning the frontend routes or presentation layer.

## Development

```sh
npm ci
npm run dev
```

## Production build

```sh
npm run build
```

Hostinger deployment settings:
- Framework: Vite
- Root directory: ./
- Build command: npm run build
- Output directory: dist
- Package manager: npm

## Backend phase
Next phase: connect the content layer to the newsroom backend/database and build authenticated admin workflows for articles, categories, states, authors, media, publishing, election coverage, ads and analytics.
