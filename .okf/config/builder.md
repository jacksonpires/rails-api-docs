---
type: Component
title: Config::Builder
description: Turns route hashes plus inferred bodies into the full config hash written to the YAML.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/builder.rb
tags: [yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: builder.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/builder.rb
---

# Overview

Groups routes by controller into sections, builds each endpoint (method, path, name, description, show,
params, body, responses).[^src] Output shape is the [YAML config format](/config/yaml-format.md).

# Non-obvious

- **Endpoint names** come from `ACTION_VERB_PHRASE` + singular/plural of the last controller segment
  (`index` → plural, others singular). Custom actions are humanized.
- **Path param typing**: `id` or `*_id` → `integer`, else `string`; always `in: path`, `required: true`.[^src]
- **Always emits `responses["200"]`** with `example: ""` — this has a rendering side-effect, see
  [scaffolded response example is always {}](/pitfalls/scaffold-response-example-empty.md).
- Verbose mode adds empty arrays (`params: []`, `body: []`) purely for discoverability
  ([pragmatic default YAML](/decisions/pragmatic-default-yaml.md)).
- `DEFAULT_GENERAL` and `verbose_field_defaults` are duplicated elsewhere — see
  [duplicated defaults](/pitfalls/duplicated-defaults.md).
