---
type: Component
title: Doc::CurlRenderer
description: Builds the copy-pasteable multi-line cURL command for an endpoint, with correct shell escaping.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/curl_renderer.rb
tags: [curl, sample-values]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: curl_renderer.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/curl_renderer.rb
---

# Precedence rules

- **Body**: `request_example` verbatim → JSON of `body` fields (each field's `example`, else
  [SampleValue](/rendering/sample-value.md)) → no `--data`.[^src]
- **URL**: each `in: path` param's `:name` replaced by its `example`, else type sample. Query params are not appended.
- **Headers**: user `headers` in YAML order, then an `Authorization` placeholder derived from `auth`
  (`bearer`/`basic`/custom string; `none` → nothing) **unless** the user already declared Authorization
  (case-insensitive).
- `Content-Type: application/json` is added only when a body is present.

# Shell escaping

Single quotes become `'\''` using the **block form** of `gsub` — see
[gsub replacement-string trap](/pitfalls/gsub-backslash-trap.md).[^src]
