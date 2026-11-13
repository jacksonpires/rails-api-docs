---
type: Data Format
title: YAML config format (config/rails-api-docs.yml)
description: The hand-edited contract between the scaffold side and the render side — general_configurations plus sections keyed by controller.
tags: [yaml, append-only]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: readme
    title: README — YAML structure / complete reference
    resource: https://github.com/jacksonpires/rails-api-docs#yaml-structure
  - id: renderer
    title: Doc::Renderer (consumer of every key)
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
---

# Overview

The only file the user maintains by hand; the HTML is always derived from it.
The full key-by-key reference is in the README[^readme] — this concept records the **contract rules**,
not the key list.

# Schema (shape)

| Path | Notes |
|------|-------|
| `general_configurations` | title, base_url, 3 colors, font_family, show_curl, show_examples. Missing keys are filled from renderer defaults at render time and from builder defaults on re-scaffold. |
| `sections.<controller_path>` | `name`, `description`, `show`, `endpoints[]`. Key is the stable controller path. |
| `endpoints[]` | Only `method` + `path` required. Identity = `"#{method} #{path}"`. |
| field arrays | `params`, `body`, `headers`, `responses.<status>.headers`, `responses.<status>.schema` — all rendered by one helper. |

# Contract rules

- `show: false` hides a section or endpoint at render time; a section with zero visible endpoints disappears.[^renderer]
- The renderer must tolerate **any** missing key — users delete freely.
- Delete an endpoint/section from the YAML to have the next `:update` regenerate it
  ([Config::Appender](/config/appender.md)).
- Inline comments are lost on re-dump; the leading header block survives ([Config::Loader](/config/loader.md)).
- Example values: see [field example is the source of truth](/decisions/field-example-source-of-truth.md).
