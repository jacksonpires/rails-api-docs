---
type: Decision
title: init and update are one generator
description: rails-api-docs:update is a namespace-only subclass of :init; the code self-detects create vs append.
tags: [cli, append-only]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: update
    title: update_generator.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/update/update_generator.rb
---

# Decision

Two names for readability (first run vs re-run), one implementation.[^update] Running `:init` on an existing
YAML is safe — it appends, exactly like `:update`.

# Rule for contributors

Add flags and logic to `InitGenerator` only. See [generators](/distribution/generators.md).
