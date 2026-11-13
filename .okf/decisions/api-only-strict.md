---
type: Decision
title: --api-only is strict on unknowns
description: When JSON-ness can't be proven statically the route is excluded, keeping the YAML clean in mixed HTML/API apps.
tags: [api-only, filtering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: readme
    title: README — Scaffolding only JSON-returning routes
    resource: https://github.com/jacksonpires/rails-api-docs#scaffolding-only-json-returning-routes---api-only
---

# Decision

Missing controller file or unresolvable parent ⇒ `:unknown` ⇒ **not** API. Only proven JSON is kept.[^readme]

# Why

Apps mixing Devise, RailsAdmin or HTML controllers would otherwise flood the YAML. A false negative costs one
manual entry; a false positive costs noise in every re-run (append-only never removes it — see
[append-only merge](/decisions/append-only-merge.md)).

Implemented by [JsonRouteDetector](/inspection/json-route-detector.md).
