---
type: Component
title: ControllerInspector
description: Prism AST pass that extracts permitted attribute names from any permit call in a controller file.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/controller_inspector.rb
tags: [prism, body-inference]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: controller_inspector.rb
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/controller_inspector.rb
---

# Overview

Parses `app/controllers/<controller>_controller.rb` with Prism and collects every literal symbol/string
argument of any `permit` call, plus the top-level keys of hash arguments.[^src] Feeds
[BodyInferrer](/inspection/body-inferrer.md). Static parsing was chosen over loading the class — see
[static analysis with Prism](/decisions/static-analysis-with-prism.md).

# Deliberately coarse

- The permit list is **per file, not per action**: the assumption is that strong params live in one
  shared `*_params` method used by both `create` and `update`.[^src] A controller with different
  permits per action gets the union on both.
- Any call named `permit` counts, regardless of receiver.
- Nested and splat permits are partial/unsupported — see [known limitations](/operations/known-limitations.md).
- Missing file → `[]` (no body inferred), never an error.
