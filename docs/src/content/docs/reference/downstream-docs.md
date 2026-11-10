---
title: Downstream Documentation Architecture
description: How Polyform scaffolds a downstream project's Astro Starlight site, Nim AST API docgen, and GitHub Pages deployment workflow.
---

Polyform maintains two distinct documentation layers in its repository:

1. **Root Generator Documentation (`docs/` + `.github/workflows/docs.yml`)**: This documentation site (`https://axiomantic.github.io/polyform/`), which documents Polyform itself, its Copier variables, and its facet architecture. Because `copier.yml` specifies `_subdirectory: template`, root `docs/` is never copied into downstream repositories.
2. **Downstream Project Documentation Template (`template/docs/` + `template/tools/docgen.nim.jinja` + `template/.github/workflows/docs.yml.jinja`)**: Rendered into downstream projects when `docs_engine == "starlight"`.

## What Downstream Projects Receive (`docs_engine="starlight"`)

When a downstream project is generated with `docs_engine="starlight"`, Polyform scaffolds:

```text
<downstream-repo>/
├── .github/workflows/docs.yml       # Automated GitHub Pages build & deploy workflow
├── tools/
│   └── docgen.nim                   # Nim AST -> Starlight Markdown API extractor
└── docs/
    ├── astro.config.mjs             # Configured with site, base, mermaid, and starlight-image-zoom
    ├── package.json                 # @astrojs/starlight, astro, astro-mermaid, starlight-image-zoom
    ├── src/
    │   ├── content.config.ts        # Starlight docsLoader() collection schema
    │   └── content/docs/
    │       ├── index.mdx            # Project landing page
    │       ├── guide/
    │       │   └── getting-started.md
    │       └── api/                 # Populated by tools/docgen.nim
    └── public/
```

## Automated Nim API Extraction (`tools/docgen.nim`)

For downstream projects with `has_nim=true`, `tools/docgen.nim` runs `nim doc --project` and transforms exported Nim procedures, types, and doc comments into Starlight-compatible Markdown pages under `docs/src/content/docs/api/`, which are automatically indexed by the Starlight sidebar (`autogenerate: { directory: 'api' }`).

## Downstream `just` Recipes

Downstream projects with `docs_engine="starlight"` include two documentation recipes in their `justfile`:

```bash
# Run Nim docgen (if has_nim) and start the local Astro Starlight dev server
just docs

# Run Nim docgen (if has_nim) and build static production assets into docs/dist/
just docs-build
```

## Downstream GitHub Pages Workflow (`.github/workflows/docs.yml`)

Whenever commits touching `docs/**`, `src/**`, `tools/**`, or `.github/workflows/docs.yml` are pushed to `main` in a downstream project, `.github/workflows/docs.yml`:

1. Installs Node.js 22 and Nim (`jiro4989/setup-nim-action@v2`).
2. Runs `nim c -r tools/docgen.nim` to refresh the `api/` reference pages.
3. Runs `cd docs && npm install && npm run build` to produce `docs/dist/`.
4. Uploads `docs/dist` via `actions/upload-pages-artifact@v3` and deploys to GitHub Pages via `actions/deploy-pages@v4`.
