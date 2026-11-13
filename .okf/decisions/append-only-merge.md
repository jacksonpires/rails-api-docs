---
type: Decision
title: Append-only merge — user edits are sacred
description: Re-running the generator only adds new routes and missing config keys; it never modifies or prunes existing YAML entries.
tags: [append-only, yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude
    title: CLAUDE.md — Sensitive areas / Config::Appender
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
  - id: readme
    title: README — Updating the YAML
    resource: https://github.com/jacksonpires/rails-api-docs#updating-the-yaml
---

# Decision

The YAML is the user's document; the code inspection is only a first draft. So on re-run,
**existing fields always win** and nothing is removed.[^claude]

# Tradeoffs accepted

- Stale endpoints (removed routes) accumulate until deleted by hand.
- Regenerating one endpoint means deleting it from the YAML and re-running `:update`.[^readme]
- Inline comments are lost because the file is re-dumped with `YAML.dump` — only the header is re-attached.

Implemented by [Config::Appender](/config/appender.md) and [Config::Loader](/config/loader.md).
