---
type: Decision
title: Self-contained HTML output
description: The output is one HTML file with all CSS and JS inlined, served live in dev and statically in production.
tags: [html]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: readme
    title: README — intro
    resource: https://github.com/jacksonpires/rails-api-docs#rails-api-docs
---

# Decision

No asset pipeline, no CDN, no JS runtime: one file droppable on any static host.[^readme] The gem is a
`development`-group dependency; production only needs the built file.

# Consequences

- All styling and behaviour live in one ERB ([HTML template](/rendering/html-template.md)); it is large by design.
- Theming is done through CSS variables fed from `general_configurations`, not separate stylesheets.
- Two delivery paths share one renderer: [dev mount](/distribution/dev-mount.md) and [build task](/distribution/build-task.md).
