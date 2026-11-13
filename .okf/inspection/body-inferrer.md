---
type: Component
title: BodyInferrer
description: Composes ControllerInspector and SchemaInspector into typed body field lists for create and update actions.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/body_inferrer.rb
tags: [body-inference, sample-values]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: body_inferrer.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/body_inferrer.rb
---

# Overview

Only `create` and `update` get a body.[^src] Names come from
[ControllerInspector](/inspection/controller-inspector.md), types from
[SchemaInspector](/inspection/schema-inspector.md); each field is seeded with
`description: ""` and `example: SampleValue.for(type)` (see [SampleValue](/rendering/sample-value.md)).

# Rules

- **`required`** = column is `NOT NULL` **and** has no default. Unknown column → `string`, not required.
- Returns `nil` (not `[]`) when nothing is permitted — [Config::Builder](/config/builder.md) uses that
  to omit the `body:` key entirely.
- Results are cached per controller so both actions share one parse.[^src]
- Verbose defaults are returned as **fresh hashes per call** — see
  [YAML anchors pitfall](/pitfalls/yaml-anchors.md). This method is duplicated in Builder — see
  [duplicated defaults](/pitfalls/duplicated-defaults.md).
