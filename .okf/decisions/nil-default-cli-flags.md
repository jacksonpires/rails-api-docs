---
type: Decision
title: CLI boolean flags default to nil
description: Generator class_options default to nil so "flag omitted" falls back to Configuration while --no-flag can override it.
tags: [cli]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: init
    title: InitGenerator#api_only? / #verbose_yaml?
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/init/init_generator.rb
---

# Decision

`class_option :api_only, type: :boolean, default: nil` (same for `verbose_yaml`, `only_controllers`).
`nil` → use [Configuration](/config/configuration.md); `true`/`false` → CLI wins.[^init]

# Why

With `default: false` there is no way to tell "not passed" from `--no-api-only`, so a persistent
`api_only = true` could never be overridden for a single run. Used by [generators](/distribution/generators.md).
