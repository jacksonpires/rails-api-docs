---
type: Component
title: JsonRouteDetector
description: Static Prism-based classifier that decides whether a route returns JSON, powering --api-only.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/json_route_detector.rb
tags: [prism, api-only, filtering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: json_route_detector.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/json_route_detector.rb
---

# Decision logic

1. Controller's superclass chain reaches `ActionController::API` → every action is JSON.
2. Otherwise, the action's `def` body contains `render` with a `json:` key (kwarg or hash-rocket,
   also inside `respond_to`) → JSON.
3. Otherwise → not JSON.[^src]

Why strict on unknowns: see [strict --api-only](/decisions/api-only-strict.md).

# Implementation notes

- Each file parsed **once per detector instance**; one AST feeds `SuperclassVisitor` and `JsonActionVisitor`.
- Parent resolution: `Api::BaseController`.underscore → `app/controllers/api/base_controller.rb`, recursively.
  A **placeholder cache entry is written before recursing** to break cycles.[^src]
- `SuperclassVisitor` takes the **first** class in the file.
- Parent from a gem (file absent) → `:unknown` (strict), but per-action `render json:` detection still runs.
- Gaps: helper methods, `render template:, formats: :json`, included modules — see
  [known limitations](/operations/known-limitations.md).
