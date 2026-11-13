---
type: Runbook
title: Release checklist
description: Steps to cut a gem release, including the packaging check that 0.1.0 missed.
tags: [packaging]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: changelog
    title: CHANGELOG.md
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CHANGELOG.md
  - id: gemspec
    title: rails-api-docs.gemspec
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/rails-api-docs.gemspec
---

# Steps

1. Bump `lib/rails-api-docs/version.rb`; add a dated CHANGELOG entry.[^changelog]
2. Full suite green on the matrix ([testing](/operations/testing.md)).
3. `gem build rails-api-docs.gemspec` and list the files: every `lib/rails-api-docs/*` subdirectory
   (including `doc/`) must be present — see [gitignore packaging pitfall](/pitfalls/gitignore-doc-packaging.md).
4. `gem push` — the gemspec sets `rubygems_mfa_required = "true"`, so MFA is required.[^gemspec]

Released so far: 0.1.0 (yanked), 0.1.1, 0.1.2.
