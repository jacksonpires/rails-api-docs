---
type: Component
title: SampleValue
description: Single source of truth for type-derived placeholder values used when a field has no example.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/sample_value.rb
tags: [sample-values]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: sample_value.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/sample_value.rb
---

# Schema

| Type | Sample |
|------|--------|
| string, text | `"example"` |
| integer, bigint | `1` |
| float, decimal | `1.0` |
| boolean | `true` |
| date | `"2026-01-01"` |
| datetime, time | `"2026-01-01T00:00:00Z"` |
| anything else | `nil` (→ JSON `null`, meaning "fill this in") |

[^src]

Consumers: [BodyInferrer](/inspection/body-inferrer.md), [Config::Builder](/config/builder.md),
[CurlRenderer](/rendering/curl-renderer.md), [Doc::Renderer](/rendering/renderer.md). New type mappings go here
only. The narrow mapping is intentional — guessing for niche types (json, uuid, …) would look authoritative.
Policy for when it applies: [field example is the source of truth](/decisions/field-example-source-of-truth.md).
