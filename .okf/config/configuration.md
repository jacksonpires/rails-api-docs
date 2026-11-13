---
type: Component
title: RailsApiDocs::Configuration
description: Global settings object — paths, dev mount toggle, route filters, api_only and verbose_yaml defaults.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/configuration.rb
tags: [filtering, cli]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: configuration.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/configuration.rb
  - id: gen
    title: InitGenerator#scoped_config
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/init/init_generator.rb
---

# Schema

| Setting | Default | Notes |
|---------|---------|-------|
| `config_path` | `config/rails-api-docs.yml` | relative to `Rails.root` |
| `output_path` | `public/api-docs.html` | build target |
| `mount_path` | `/rails/api-docs` | [dev mount](/distribution/dev-mount.md) |
| `mount_in_development` | `true` | |
| `ignored_path_prefixes` / `ignored_controllers` / `ignored_actions` | `[]` | blacklists |
| `only_controllers` | `[]` | whitelist; empty = inactive |
| `api_only` | `false` | see [JsonRouteDetector](/inspection/json-route-detector.md) |
| `verbose_yaml` | `false` | see [pragmatic default YAML](/decisions/pragmatic-default-yaml.md) |
| `route_source` | lazy `Rails.application.routes` | injectable for tests |

[^src]

# Precedence

CLI flags win over this object. The generator builds a **per-run dup** (`scoped_config`) and overlays
CLI values on it, so a run never mutates global state.[^gen] See [generators](/distribution/generators.md)
and [nil-default CLI flags](/decisions/nil-default-cli-flags.md).
