---
type: Runbook
title: Running tests and the compatibility matrix
description: How to run the minitest suite locally, per Rails version, in CI, and the end-to-end smoke scripts.
resource: https://github.com/jacksonpires/rails-api-docs/blob/main/.github/workflows/ci.yml
tags: [testing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: ci
    title: .github/workflows/ci.yml
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/.github/workflows/ci.yml
  - id: claude
    title: CLAUDE.md — How to run
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
---

# Local

```bash
bundle install
bundle exec rake test                     # ~185 runs, < 1s
BUNDLE_GEMFILE=gemfiles/rails_7.1.gemfile bundle exec rake test
```

Tests drive a real `ActionDispatch::Routing::RouteSet` (injected via `route_source`) — no dummy app.

# Matrix

CI runs Ruby 3.1–4.0 × Rails 7.1–8.1 (Ruby 3.1 excluded for Rails 8.x).[^ci] Adding a Rails minor =
new `gemfiles/rails_X.Y.gemfile` + CI matrix entry + README compatibility table. The `rails` dev dependency is in
the root `Gemfile` (not the gemspec) so per-version gemfiles can pin it without Bundler override warnings.[^claude]

# Smoke tests

`/tmp/rad_smoke_test.sh` (real host app, hits `/rails/api-docs`) and `/tmp/rad_smoke_build.sh`
(rake task, `OUTPUT=`, missing-config branch). They live outside the repo and may not exist on a new machine.

Quirks: [test and Ruby 3 quirks](/pitfalls/ruby-testing-quirks.md).
