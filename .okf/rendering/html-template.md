---
type: Component
title: HTML template (api_docs.html.erb)
description: The single ERB template holding layout, inlined CSS theme variables and the client-side JS (search, tag filter, tabs, copy).
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/templates/api_docs.html.erb
tags: [html]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: api_docs.html.erb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/templates/api_docs.html.erb
  - id: changelog
    title: CHANGELOG 0.1.2 — tag-filter pill fix
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CHANGELOG.md
---

# Overview

Three-column layout: sidebar (search + tag filter), central field tables, right column with cURL and
per-status response tabs. Colors flow from `general_configurations` into CSS custom properties.[^src]
Rendered by [Doc::Renderer](/rendering/renderer.md).

# Conventions

- **Trim mode `-`**: control tags end with `-%>`. New tags must follow it or the output sprouts blank lines.
- Never expand field markup inline — call `render_fields(...)`.
- `show_curl` / `show_examples` gate the right column blocks.
- Client JS: text search ANDs with a single exclusive tag filter; copy buttons use
  `navigator.clipboard` with an `execCommand('copy')` fallback for non-secure contexts.
- CSS rules that set `display` on an element toggled via the `hidden` attribute need an explicit
  `[hidden] { display: none }` — this was the 0.1.2 "Filtered by" pill bug.[^changelog]
- `preview/api-docs.html` is the original static mockup, **not** gem output; `preview/api-docs-rendered*.html`
  are real renders kept for visual comparison.
