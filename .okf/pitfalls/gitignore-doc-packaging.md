---
type: Pitfall
title: Unanchored gitignore pattern dropped lib/.../doc from the gem
description: A "doc/" ignore pattern matched lib/rails-api-docs/doc/, so 0.1.0 shipped without its renderers and was yanked.
tags: [packaging]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: changelog
    title: CHANGELOG 0.1.1
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CHANGELOG.md
---

# What happened

The gemspec builds its file list from git, and `.gitignore` had `doc/`, which matches a `doc/` directory
at **any depth**. `lib/rails-api-docs/doc/*` (renderer, curl renderer, responder, file builder) was never
committed, 0.1.0 crashed at boot with `cannot load such file`, and was yanked.[^changelog]

# Rule

Anchor root-only ignores (`/doc/`). Before releasing, inspect the built gem's file list for every
`lib/` subdirectory. See [release checklist](/operations/release.md).
