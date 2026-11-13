---
type: Pitfall
title: Duplicated defaults that can drift
description: DEFAULT_GENERAL exists in both Builder and Renderer, and verbose_field_defaults in both Builder and BodyInferrer.
tags: [drift-risk]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T14:00:00Z
sources:
  - id: builder
    title: Config::Builder::DEFAULT_GENERAL / #verbose_field_defaults
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/builder.rb
  - id: renderer
    title: Doc::Renderer::DEFAULT_GENERAL
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
  - id: bi
    title: BodyInferrer#verbose_field_defaults
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/body_inferrer.rb
---

# Problem

Two identical copies each of:

- `DEFAULT_GENERAL` — in [Config::Builder](/config/builder.md)[^builder] (what gets scaffolded) and
  [Doc::Renderer](/rendering/renderer.md)[^renderer] (what fills missing keys at render time).
- `verbose_field_defaults` — in Builder (path params) and [BodyInferrer](/inspection/body-inferrer.md)[^bi] (body fields).

Changing a default color/title or adding a verbose key in one place only will make scaffold and render
disagree. CLAUDE.md's "Where to edit what" table lists both copies.

# Rule

Edit both copies together (and the CSS vars in the template), or consolidate into one module.
