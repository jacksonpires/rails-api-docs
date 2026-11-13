---
type: Component
title: SchemaInspector
description: Best-effort lookup of the ActiveRecord model behind a controller to get column type, nullability and default.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/schema_inspector.rb
tags: [body-inference]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: schema_inspector.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/schema_inspector.rb
---

# Overview

Resolves the model by taking the **last** controller segment, singularizing and camelizing it
(`api/v1/users` → `User`), then reads `columns_hash`.[^src] Feeds [BodyInferrer](/inspection/body-inferrer.md).

# Non-obvious

- **Namespace is discarded**: `admin/users` resolves to top-level `User`, never `Admin::User`.
- It rescues `StandardError` and returns `{}` — DB not reachable, model missing, anything. Schema
  inference failing is invisible by design; fields just fall back to `string` / not required.[^src]
- The resolver is injectable (`model_resolver:`), which is how tests avoid ActiveRecord.
- Custom inflections affect resolution — see [known limitations](/operations/known-limitations.md).
