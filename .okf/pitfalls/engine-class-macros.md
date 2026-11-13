---
type: Pitfall
title: Engine rake_tasks/generators must be class-body macros
description: rake_tasks and generators blocks silently do nothing if moved inside an initializer.
tags: [rails-engine]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: engine
    title: engine.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/engine.rb
---

# Rule

`rake_tasks do … end` and `generators do … end` are Railtie class-level hooks; they must sit directly in the
`Engine` class body, not inside `initializer "…" do`.[^engine] This broke once during a reorganization.
Only the mount lives in an initializer — see [dev mount](/distribution/dev-mount.md).
