---
type: Overview
title: Generation and rendering pipeline
description: How routes, controllers and AR schema become an editable YAML, and how that YAML becomes one self-contained HTML page.
tags: [yaml, html, prism]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: entry
    title: lib/rails-api-docs.rb (require order)
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs.rb
  - id: generator
    title: InitGenerator#create_or_update_config_file
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/generators/rails-api-docs/init/init_generator.rb
  - id: renderer
    title: Doc::Renderer
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/renderer.rb
---

# Overview

The gem has **two halves joined by one hand-edited file**, `config/rails-api-docs.yml`:

1. **Scaffold (write side)** — run by the generators, at dev time only.[^generator]
   [RouteInspector](/inspection/route-inspector.md) lists routes →
   optional [JsonRouteDetector](/inspection/json-route-detector.md) filter (`--api-only`) →
   [BodyInferrer](/inspection/body-inferrer.md) (which composes
   [ControllerInspector](/inspection/controller-inspector.md) + [SchemaInspector](/inspection/schema-inspector.md)) →
   [Config::Builder](/config/builder.md) assembles the hash →
   either written fresh or merged by [Config::Appender](/config/appender.md).
2. **Render (read side)** — [Config::Loader](/config/loader.md) parses the YAML →
   [Doc::Renderer](/rendering/renderer.md) (ERB + [CurlRenderer](/rendering/curl-renderer.md)) → one HTML string.[^renderer]
   That string is served live by the [dev mount](/distribution/dev-mount.md) or written to disk by the
   [build task](/distribution/build-task.md).

The two halves never talk directly: the YAML is the contract (see [YAML config format](/config/yaml-format.md)).
That is why the render side tolerates any missing key — the user may have deleted it.

# Load order

Everything is required eagerly from the entry file; the Engine is only loaded when
`Rails::Engine` is defined, so the pure-Ruby pieces stay unit-testable without Rails.[^entry]

# Working on the gem

Before changing anything, run the suite as in [testing](/operations/testing.md); before shipping, follow the
[release checklist](/operations/release.md). Accepted gaps are in [known limitations](/operations/known-limitations.md).
