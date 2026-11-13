---
type: Decision
title: Static analysis with Prism instead of loading controllers
description: Controllers are parsed as source with Prism rather than introspected at runtime, trading precision for zero side effects.
tags: [prism]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: gemspec
    title: rails-api-docs.gemspec (prism >= 0.24 dependency)
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/rails-api-docs.gemspec
---

# Decision

Permits and JSON-ness are read from the controller **source file** via Prism (a runtime dependency,
`prism >= 0.24`[^gemspec]), never by loading/instantiating controller classes.

# Why

- No side effects from loading app code (before_actions, constants, DB connections).
- Works even when a controller can't be loaded in the generator's context.
- Prism is the stock Ruby parser going forward, so the AST API is stable across Ruby 3.1–4.0.

# Cost

Anything dynamic is invisible: splat permits, helpers, included modules, metaprogrammed renders.
The gem prefers **missing a field** (user adds it) over **inventing one**. See
[ControllerInspector](/inspection/controller-inspector.md), [JsonRouteDetector](/inspection/json-route-detector.md),
[known limitations](/operations/known-limitations.md).
