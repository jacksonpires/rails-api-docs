# Changelog

## [0.1.1] - 2026-06-03

### Fixed

- **Critical packaging bug.** `lib/rails-api-docs/doc/` files
  (`curl_renderer`, `renderer`, `responder`, `file_builder`) were
  silently excluded from the 0.1.0 release because the `doc/` pattern
  in `.gitignore` matched **any** `doc/` directory at any depth, not
  just the repository root. Installing 0.1.0 produced
  `cannot load such file -- …/lib/rails-api-docs/doc/curl_renderer`
  at boot. Tightened the gitignore pattern to `/doc/` so it only
  ignores the top-level `doc/` directory (RDoc/YARD output). 0.1.0 has
  been yanked from RubyGems.

## [0.1.0] - 2026-06-02 [YANKED]

Initial release — **yanked**. See 0.1.1 for the first usable version.

### Inspection & inference

- **`Inspectors::RouteInspector`**: walks `Rails.application.routes`,
  normalizes paths (strips `(.:format)`), filters Rails internals
  (`/rails/info`, `/rails/active_storage`, …), groups by controller,
  supports multi-verb `match` and namespaced paths (`api/v1/users`).
- **`Inspectors::ControllerInspector`** (Prism AST): extracts permitted
  attribute names from `params.permit(:a, :b, …)` calls anywhere in the
  controller file. Handles flat permits, hash-rocket form, and nested
  permits (top-level keys only).
- **`Inspectors::SchemaInspector`**: resolves controller → ActiveRecord
  model and reads `columns_hash` for type and nullability metadata.
  Best-effort — returns `{}` when the model can't be resolved.
- **`Inspectors::BodyInferrer`**: composes Controller + Schema to produce
  typed `body:` field lists for `create`/`update` actions, with sensible
  fallbacks (`string` type, `required: false`) when inspectors come up
  empty.
- **`Inspectors::JsonRouteDetector`** (Prism AST): decides if an endpoint
  is JSON-returning. Walks the controller's superclass chain looking for
  `ActionController::API`; falls back to per-action `render json:`
  detection inside `DefNode` bodies (kwarg and hash-rocket form, inside
  `respond_to` blocks too). Cached per-controller.

### YAML generation & merge

- **`Config::Builder`**: assembles the full config — `general_configurations`
  with Rails-themed defaults (`#CC0000` primary), `sections` grouped by
  controller, endpoints with method/path/name/description/show, inferred
  path params, body fields from the inferrer, and a response stub.
- **`Config::Appender` (append-only re-runs)**: re-running
  `rails g rails-api-docs:update` only adds new routes; existing entries —
  including user edits to descriptions, body fields, examples, headers,
  responses — are never modified. Endpoint identity is `"#{method} #{path}"`.
- **`Config::Loader`**: parses existing YAML; `Loader.header` extracts
  the leading `#`-comment block so it survives re-runs verbatim.
- **`RailsApiDocs::SampleValue`**: single source of truth for
  type-derived placeholder values (`integer → 1`, `string → "example"`,
  `date → "2026-01-01"`, …). Shared between inferrer, builder, curl
  renderer, and HTML renderer.

### Generators

- **Two generator commands** (one implementation): `rails-api-docs:init`
  for the first scaffold and `rails-api-docs:update` for re-runs.
  `UpdateGenerator < InitGenerator` aliases the namespace; same code, same
  flags, semantically distinct invocation.
- **`--api-only`**: filters scaffold to JSON-returning routes only,
  via `JsonRouteDetector`. Persistent via
  `RailsApiDocs.configuration.api_only = true`.
- **`--only-controllers`**: whitelist controllers by name. Accepts
  space-, comma-, or bracket-separated forms
  (`users posts`, `users,posts`, `[users,posts]`). Bare names match
  across namespaces (`users` matches `users` and `api/v1/users`);
  slash-qualified names are exact. Persistent via
  `RailsApiDocs.configuration.only_controllers = […]`.
- **`--verbose-yaml`**: emits every possible YAML key per endpoint and
  field with defaults (full discoverability at the cost of file size).
  Persistent via `RailsApiDocs.configuration.verbose_yaml = true`.
  Composes with all other flags.
- **Other filtering knobs**: `Configuration#ignored_path_prefixes`,
  `#ignored_controllers` (strings or regexps; same boundary-aware
  matching as `only_controllers`), `#ignored_actions`. Blacklist wins
  over whitelist when both apply.

### YAML schema

- **Pragmatic default**: every inferred body field and path param ships
  with `description: ""` and `example: <type-sample>` — users edit
  values without remembering key names. A minimal `responses["200"]`
  stub is included for every endpoint.
- **Verbose mode** additionally emits `format`, `enum`, `default`,
  `min`/`max`, `min_length`/`max_length`, `pattern`, `read_only`,
  `write_only`, `nullable` per field; and `deprecated`, `auth`, `tags`,
  `headers`, `request_example`, plus a full `responses["200"]` with
  `headers: []` and `schema: []`.
- **Response shape**: `responses["XXX"]` accepts `description`,
  `example` (raw string), `headers` (array of field hashes), and
  `schema` (typed response fields rendered as field rows).

### HTML renderer

- **Three-column self-contained output**: sidebar, central column with
  field tables, right column with cURL and response examples. All CSS
  and JS inlined — no external assets, no asset pipeline.
- **CSS variables driven by `general_configurations`**: changing
  `primary_color` / `secondary_color` re-themes the whole page.
- **Unified `render_field` helper**: single source of truth for field
  rendering. Used by body, params, request headers, response headers,
  and response schema. Renders all field-level attributes as badges,
  metas, descriptions, and inline `Example:` lines.
- **Endpoint-level badges**: `deprecated` (red badge + strikethrough
  title), `auth` (dark monospace badge: "Bearer auth", "Basic auth",
  custom), `tags` (clickable chips).
- **`Doc::CurlRenderer`**: multi-line cURL with proper shell escaping
  (single quotes via the `'\''` block-form `gsub`). Supports
  `request_example` overrides, per-param `example:` substitution in the
  URL, and auto-injects user-declared `headers:` plus an `Authorization`
  placeholder when `auth:` is set.
- **Multi-response support**: `responses:` keyed by status code with
  per-status tabs in the right column (2xx green, 4xx amber, 5xx red);
  the central column renders headers + schema per status when present.
- **Response title + copy buttons**: every cURL block and response
  block has a `<button>` copy icon that copies the currently-active
  `<pre>` content (curl command or active response tab). Uses
  `navigator.clipboard.writeText` with `document.execCommand('copy')`
  fallback for non-secure contexts. Visual flash + checkmark on success.
- **Tag click filtering**: clicking a tag pill filters the sidebar to
  endpoints carrying that tag. Single-tag exclusive with toggle (same
  tag = clear, different tag = switch). Combines with the text search
  via AND. "Filtered by: <tag> ×" pill shown between search and section
  list. Accessible: `<button>` elements, `aria-pressed`, `aria-live`.
- **Field example propagation**: `field["example"]` is the single
  source of truth for sample values — it flows into the cURL `--data`
  body and into the default response example block, with the
  type-derived sample as fallback.

### Distribution

- **Dev mount at `/rails/api-docs`**: `Rails::Engine` mounts a
  `DocsController` in `development` that re-renders the HTML from the
  current YAML on every request — no build step while iterating.
  Friendly setup page when YAML doesn't exist yet.
- **`rake rails-api-docs:build`**: reads the YAML and writes
  `public/api-docs.html`. Supports `CONFIG=` and `OUTPUT=` env overrides.
- **Publish-ready gemspec metadata**: `homepage_uri`, `source_code_uri`
  (pointing at `/tree/main` so RubyGems shows both), `changelog_uri`,
  `bug_tracker_uri`, `documentation_uri`, and
  `rubygems_mfa_required = "true"` (enforces MFA on every `gem push`).

### Tests

- 185 minitest cases covering inspectors, config build/append/load,
  renderer, curl renderer, file builder, responder, init/update
  generators, and JSON route detector. Uses
  `ActionDispatch::Routing::RouteSet` directly — no dummy Rails app
  required.
