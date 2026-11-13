---
type: Component
title: RouteInspector
description: Normalizes the Rails route set into flat route hashes and applies built-in and user filters.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/route_inspector.rb
tags: [filtering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: route_inspector.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/route_inspector.rb
---

# Overview

First stage of the [pipeline](/overview/pipeline.md). Emits one hash per (route × verb):
`{ verb:, path:, controller:, action:, name:, path_params: }`.[^src]

# Behaviour worth knowing

- **Filter order:** controller blacklist → controller whitelist → action blacklist → path
  internal/user prefixes. Blacklist effectively wins over whitelist because it runs first.
  Matching rules live in [controller matching](/config/controller-matching.md).
- **`INTERNAL_PREFIXES` is hardcoded** (`/rails/info`, `/rails/conductor`, `/rails/mailers`,
  `/rails/active_storage`, `/rails/action_mailbox`, `/action_cable`, `/assets`). New Rails-core
  prefixes must be added here; user `ignored_path_prefixes` only add to it.[^src]
- Routes without `controller`/`action` defaults (e.g. engine mounts, redirects) are silently skipped —
  this also keeps the gem's own [dev mount](/distribution/dev-mount.md) out of the docs.
- Paths are normalized: `(.:format)` and trailing `/` stripped; empty becomes `/`.
- Multi-verb `match via: [...]` arrives as `"GET|POST"` and is split into separate entries.
- Path params are extracted with `/:(\w+)/` — glob segments (`*path`) are not captured.[^src]
