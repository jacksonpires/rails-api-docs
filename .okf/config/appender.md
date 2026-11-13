---
type: Component
title: Config::Appender
description: Append-only merge of a freshly generated config into the existing YAML, where existing entries always win.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/appender.rb
tags: [append-only, yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: appender.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/config/appender.rb
  - id: tests
    title: test/config/appender_test.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/test/config/appender_test.rb
---

# Rules

- Endpoint identity: `"#{method} #{path}"`.
- Existing endpoints are kept **verbatim**; generated ones only appended when their identity is new.
- New sections appended at the end; existing section metadata (name, description, show) untouched.
- `general_configurations`: `generated.merge(existing)` — existing keys win, missing keys filled in,
  so a new gem option never forces a manual edit.[^src]
- `changes?`/`diff` drive the generator's `unchanged` vs `updated (+N section(s), +M endpoint(s))` status.

Why: [append-only merge](/decisions/append-only-merge.md).

# Consequences

- Removed routes are **never** pruned from the YAML.
- Changing a route's path or verb creates a new endpoint; the old one stays (user deletes it).
- Moving a route to a different controller key appends it to the new section even if the identical
  identity exists under the old one (identity is checked per section).[^src]

# Guardrail

Any change here must keep `appender_test.rb` covering: user edits survive, existing
`general_configurations` never overwritten (new keys added), header comments preserved.[^tests]
