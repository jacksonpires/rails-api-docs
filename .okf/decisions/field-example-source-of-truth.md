---
type: Decision
title: field example is the source of truth for sample values
description: Every place that needs a sample value prefers the field's own example and falls back to SampleValue.for(type).
tags: [sample-values]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude
    title: CLAUDE.md — field["example"] is the single source of truth
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
---

# Decision

Precedence everywhere: **user `example` → `SampleValue.for(type)`**.[^claude] The scaffold seeds `example`
on every inferred field, so the fallback is mostly for hand-added fields without one.

Applies in [CurlRenderer](/rendering/curl-renderer.md) (`--data`, path params, headers) and in
[Doc::Renderer](/rendering/renderer.md)'s synthesized response. Any new placeholder site must follow the same
order and call [SampleValue](/rendering/sample-value.md).
