---
type: Component
title: Controller matching rule
description: The shared rule used by ignored_controllers and only_controllers — regexp, exact path, or boundary-aware suffix.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/route_inspector.rb
tags: [filtering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: RouteInspector#controller_matches?
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/route_inspector.rb
---

# Rule

| Pattern | Match |
|---------|-------|
| `Regexp` | `Regexp#match?` |
| String with `/` | exact (`api/v1/users` matches only itself) |
| String without `/` | equal **or** ends with `/<pattern>` (`users` ⇒ `users`, `api/v1/users`; not `super_users`) |

[^src]

Both lists share this one method so they stay symmetric. Blacklist wins when both match.
Before v0.1.0 shipped, `ignored_controllers` was exact-match; it was switched to this rule with no migration
impact because nothing had been released. Used by [RouteInspector](/inspection/route-inspector.md),
configured via [Configuration](/config/configuration.md).
