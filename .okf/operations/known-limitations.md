---
type: Limitation
title: Known limitations (do not fix without an explicit ask)
description: Accepted gaps in inference, detection and YAML round-tripping that are intentional or deferred.
tags: [prism, yaml, api-only]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude
    title: CLAUDE.md — Known limitations
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
  - id: readme
    title: README — Limitations / --api-only known gaps
    resource: https://github.com/jacksonpires/rails-api-docs#limitations
---

# List

| Limitation | Where |
|-----------|-------|
| Nested permits → top-level keys only | [ControllerInspector](/inspection/controller-inspector.md) |
| Splat permits (`permit(*ARGS)`) not resolved | [ControllerInspector](/inspection/controller-inspector.md) |
| Inline YAML comments lost on re-run | [Config::Loader](/config/loader.md) |
| PATCH and PUT for one update → two endpoints (intentional; hide one with `show: false`) | [RouteInspector](/inspection/route-inspector.md) |
| `new`/`edit` included by default (opt out via `ignored_actions`) | [RouteInspector](/inspection/route-inspector.md) |
| Custom inflections may misname sections / miss models | [SchemaInspector](/inspection/schema-inspector.md) |
| `--api-only` misses helper-method renders, `render template:, formats: :json`, included modules | [JsonRouteDetector](/inspection/json-route-detector.md) |

[^claude] [^readme]

The CLAUDE.md rule: these are known and **must not be "fixed" without an explicit request**.
Root cause for most of them: [static analysis with Prism](/decisions/static-analysis-with-prism.md).
