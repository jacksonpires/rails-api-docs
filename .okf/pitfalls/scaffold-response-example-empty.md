---
type: Pitfall
title: Scaffolded endpoints always show {} as the response example
description: Because the scaffold always writes responses["200"] with example "", the renderer's synthesized response from body examples never runs for them.
tags: [sample-values, html]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: builder
    title: Config::Builder#response_stub
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/builder.rb
  - id: renderer
    title: Doc::Renderer#responses_for / #default_response_example
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
  - id: tpl
    title: api_docs.html.erb response body block
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/templates/api_docs.html.erb
---

# Behaviour

- [Config::Builder](/config/builder.md) emits `responses: { "200": { description: "", example: "" } }` on every endpoint.[^builder]
- [Doc::Renderer](/rendering/renderer.md)`#responses_for` honours a non-empty `responses` hash verbatim and only
  synthesizes from body examples (`default_response_example`) when `responses` is absent.[^renderer]
- The template replaces a blank example with `{}`.[^tpl]

So for a freshly scaffolded `create`, the cURL shows the inferred body but the response panel shows `{}`.
The [field-example rule](/decisions/field-example-source-of-truth.md) only reaches the response panel for
hand-written endpoints without `responses`.

# Status

Observed from code on 2026-11-13; not yet decided whether this is intended. Treat as a known quirk until confirmed.
