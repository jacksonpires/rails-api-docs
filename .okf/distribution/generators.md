---
type: Component
title: init / update generators
description: rails g rails-api-docs:init and :update — one implementation that scaffolds fresh or appends, with CLI filter flags.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/init/init_generator.rb
tags: [cli, append-only, filtering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: init
    title: init_generator.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/init/init_generator.rb
  - id: update
    title: update_generator.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/update/update_generator.rb
---

# Overview

`UpdateGenerator < InitGenerator` and only overrides `namespace` + `desc`; Thor carries `class_option`s to
subclasses, so new flags/logic go in `InitGenerator` only.[^update] Behaviour self-detects: file missing → fresh
scaffold with header; file present → [Config::Appender](/config/appender.md) merge. See
[init and update are one generator](/decisions/init-update-alias.md).

# Flags

| Flag | Effect |
|------|--------|
| `--api-only` / `--no-api-only` | filter via [JsonRouteDetector](/inspection/json-route-detector.md) |
| `--only-controllers` | whitelist; accepts `a b`, `a,b`, `[a,b]`, `[ a , b ]` |
| `--verbose-yaml` | every key with defaults |

[^init]

- `namespace "rails-api-docs:init"` is **forced**; without it Rails infers `rails_api_docs:init` from the module.
- All flags default to `nil` — see [nil-default CLI flags](/decisions/nil-default-cli-flags.md).
- Repeating `--only-controllers` does **not** merge — Thor keeps the last occurrence.
- Filtering is scaffold-time only: re-running with `--api-only` never removes HTML routes already in the YAML.
