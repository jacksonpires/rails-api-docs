---
type: Component
title: Dev mount (/rails/api-docs)
description: Engine route appended in development that re-renders the docs from the YAML on every request, or shows a setup page.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/engine.rb
tags: [rails-engine, html]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: engine
    title: engine.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/engine.rb
  - id: responder
    title: doc/responder.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/responder.rb
  - id: controller
    title: app/controllers/rails_api_docs/docs_controller.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/app/controllers/rails_api_docs/docs_controller.rb
---

# Overview

The `rails_api_docs.mount` initializer **appends** a mount at `mount_path` only when
`mount_in_development && Rails.env.development?`.[^engine] Production never registers it; it serves the
file produced by the [build task](/distribution/build-task.md).

# Pieces

- `DocsController < ActionController::Base` with `layout false` (page is a full `<html>`), delegates to
  `Doc::Responder`.[^controller]
- `Doc::Responder` is pure Ruby so the decision (YAML present → 200 render; missing → 404 setup page telling
  you to run `rails g rails-api-docs:init`) is unit-testable without booting Rails.[^responder]
- No caching: each request re-reads the YAML, which is the whole point of the edit-and-refresh loop.
- `rake_tasks` / `generators` blocks must stay at Engine class-body level — see
  [engine macros pitfall](/pitfalls/engine-class-macros.md).
