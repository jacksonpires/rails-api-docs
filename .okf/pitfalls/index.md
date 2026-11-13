# Pitfalls

* [gsub backslash trap](gsub-backslash-trap.md) - Use the block form when shell-escaping single quotes.
* [Engine class macros](engine-class-macros.md) - rake_tasks/generators must stay in the Engine class body.
* [gitignore packaging bug](gitignore-doc-packaging.md) - Unanchored doc/ pattern dropped files from 0.1.0.
* [YAML anchors](yaml-anchors.md) - Shared default objects produce anchors in the scaffold.
* [Duplicated defaults](duplicated-defaults.md) - DEFAULT_GENERAL and verbose_field_defaults exist twice.
* [Scaffolded response example is always {}](scaffold-response-example-empty.md) - The synthesized response never runs for scaffolded endpoints.
* [Test and Ruby 3 quirks](ruby-testing-quirks.md) - render helper clash; brace string-keyed hashes.
