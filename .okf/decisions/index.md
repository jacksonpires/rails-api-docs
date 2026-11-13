# Decisions

* [Append-only merge](append-only-merge.md) - Re-runs only add; existing YAML entries are never modified or pruned.
* [Static analysis with Prism](static-analysis-with-prism.md) - Parse controller source instead of loading classes.
* [--api-only is strict](api-only-strict.md) - Unprovable routes are excluded.
* [Self-contained HTML](self-contained-html.md) - One file, everything inlined.
* [Pragmatic default YAML](pragmatic-default-yaml.md) - Commonly edited keys by default; --verbose-yaml for everything.
* [Field example is the source of truth](field-example-source-of-truth.md) - User example first, SampleValue fallback.
* [init and update are one generator](init-update-alias.md) - Namespace-only subclass.
* [CLI flags default to nil](nil-default-cli-flags.md) - Distinguishes omitted from explicitly off.
