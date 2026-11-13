---
type: Pitfall
title: Shared default objects make YAML.dump emit anchors
description: Reusing the same hash/array instance across fields produces &1/*1 anchors in the scaffold; defaults must be fresh per call.
tags: [yaml]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: bi
    title: BodyInferrer#verbose_field_defaults comment
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/inspectors/body_inferrer.rb
---

# Rule

`YAML.dump` turns object identity into anchors (`enum: &1 []` … `enum: *1`). Verbose defaults are therefore
**methods returning new hashes**, not frozen constants.[^bi] Applies to [Config::Builder](/config/builder.md)
and [BodyInferrer](/inspection/body-inferrer.md).
