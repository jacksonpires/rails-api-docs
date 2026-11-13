---
type: Component
title: Doc::Renderer
description: Turns the parsed YAML into the self-contained HTML page via ERB, with render_field as the single field-markup helper.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
tags: [html]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: renderer.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
---

# Overview

`ERB.new(template, trim_mode: "-").result(binding)` — template helpers are **public** methods so the ERB
binding reaches them.[^src] Template: [HTML template](/rendering/html-template.md). Output is a single string
with all CSS/JS inlined — see [self-contained HTML](/decisions/self-contained-html.md).

# Rules worth keeping

- **`render_field` is the only place field markup is built**; body, params, request headers, response headers
  and response schema all go through it. Badge order is fixed: format → in → read-only → write-only →
  nullable → required → min/max/default/pattern metas.[^src] Add a new per-field attribute there, never inline in ERB.
- `general` merges YAML over its own `DEFAULT_GENERAL` (a copy — see [duplicated defaults](/pitfalls/duplicated-defaults.md)).
- `visible_sections` drops `show: false` sections/endpoints and sections left empty.
- `responses_for` honours `responses:` verbatim when present; otherwise synthesizes one `200` from
  `response_example` or the body sample. Because the scaffold always writes `responses`, the synthesized
  path rarely runs — see [scaffolded response example is always {}](/pitfalls/scaffold-response-example-empty.md).
- `endpoint_id` (section slug + method + slugged path) is the DOM anchor; changing it breaks deep links.
