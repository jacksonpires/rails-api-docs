---
type: Decision
title: Pragmatic default YAML, verbose opt-in
description: The scaffold emits only commonly edited keys by default; --verbose-yaml emits every key for discoverability at ~10x size.
tags: [yaml, cli]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude
    title: CLAUDE.md — Pragmatic vs verbose YAML scaffold
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/CLAUDE.md
---

# Decision

Default: `description` + `example` on every inferred field and a minimal `responses["200"]` stub.
Verbose: every field/endpoint key with defaults, roughly 10× more lines per endpoint.[^claude]

# Why

Users edit values far more often than they discover keys; a short file is easier to maintain under
[append-only merge](/decisions/append-only-merge.md). Verbose exists for first-time exploration.

Verbose defaults are produced by methods returning fresh objects — see [YAML anchors](/pitfalls/yaml-anchors.md).
Implemented in [Config::Builder](/config/builder.md) and [BodyInferrer](/inspection/body-inferrer.md).
