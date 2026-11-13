---
type: Component
title: Config::Loader
description: Safe YAML loading plus extraction of the leading comment header so it survives re-runs.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/loader.rb
tags: [yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: loader.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/loader.rb
---

# Overview

- `load` uses `YAML.safe_load` permitting only `Symbol`, `Date`, `Time`; a missing file returns `{}`.[^src]
- `header` returns the leading run of `#` and blank lines. The generator re-prepends it after
  `YAML.dump`, which is the **only** reason user comments at the top survive. Comments anywhere else are lost —
  see [known limitations](/operations/known-limitations.md).
- Used by both halves of the [pipeline](/overview/pipeline.md): generator (merge) and renderer (display).
