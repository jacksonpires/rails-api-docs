---
type: Component
title: rake rails-api-docs:build
description: Writes the self-contained HTML (default public/api-docs.html) from the YAML, with CONFIG= and OUTPUT= overrides.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/tasks/rails-api-docs.rake
tags: [html, cli]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: task
    title: rails-api-docs.rake
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/tasks/rails-api-docs.rake
  - id: fb
    title: doc/file_builder.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/file_builder.rb
---

# Overview

Thin rake body over `Doc::FileBuilder`, extracted so the build flow is unit-testable.[^task]
`ENV["CONFIG"]` / `ENV["OUTPUT"]` override [Configuration](/config/configuration.md) paths (both resolved
against `Rails.root`). Missing YAML raises `MissingConfigError` → message on stderr, `exit 1`.
FileBuilder creates the output directory if needed.[^fb]

Both the build and the [dev mount](/distribution/dev-mount.md) render through the same
[Doc::Renderer](/rendering/renderer.md), so the dev view is exactly what ships.
