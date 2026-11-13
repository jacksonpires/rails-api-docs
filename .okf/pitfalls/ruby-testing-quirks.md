---
type: Pitfall
title: Test and Ruby 3 quirks
description: Generator TestCase clashes with a helper named render, and string-keyed hashes must be braced when passed next to kwargs.
tags: [testing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude
    title: CLAUDE.md — Conventions
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
---

# Rules

- In `Rails::Generators::TestCase` tests, don't define a helper called `render` — it collides. Use another name.[^claude]
- Hashes with string keys passed to a method that also takes kwargs: always wrap in explicit `{}`; Ruby 3 can
  otherwise treat them as keyword arguments.

See [testing](/operations/testing.md).
