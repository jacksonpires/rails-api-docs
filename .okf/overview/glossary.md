---
type: Overview
title: Glossary
description: Terms used across the gem's code and docs — section, endpoint identity, scaffold, verbose YAML, dev mount.
tags: [yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
---

# Terms

| Term | Meaning |
|------|---------|
| **Section** | One controller's group of endpoints in the YAML, keyed by controller path (`api/v1/users`). The key is stable; `name` is display-only. See [YAML config format](/config/yaml-format.md). |
| **Endpoint identity** | `"#{method} #{path}"` — the only thing [Config::Appender](/config/appender.md) uses to decide whether a route is new. |
| **Scaffold** | The YAML produced by the generators from code inspection ([pipeline](/overview/pipeline.md)). |
| **Pragmatic vs verbose YAML** | Default scaffold emits only commonly edited keys; `--verbose-yaml` emits every key. See [the decision](/decisions/pragmatic-default-yaml.md). |
| **Dev mount** | The engine route at `/rails/api-docs` that re-renders on every request. See [dev mount](/distribution/dev-mount.md). |
| **Internal prefixes** | Rails-core paths always hidden by [RouteInspector](/inspection/route-inspector.md); user filters stack on top. |
| **Field** | Any row rendered by `render_field`: body field, param, request/response header, response schema entry. See [Doc::Renderer](/rendering/renderer.md). |
