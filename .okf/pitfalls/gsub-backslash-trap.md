---
type: Pitfall
title: gsub replacement-string backslash trap in shell escaping
description: str.gsub("'", "'\\''") treats \' as the post-match reference; the block form must be used.
tags: [curl, testing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: src
    title: CurlRenderer#shell_escape
    resource: https://github.com/jacksonpires/rails-api-docs/blob/main/lib/rails-api-docs/doc/curl_renderer.rb
---

# Problem

In a `gsub` replacement **string**, `\'` means "post-match", so the string form duplicates content instead of
escaping quotes.

# Rule

Keep `str.gsub("'") { "'\\''" }` (block form).[^src] If touched, run
`test_escapes_single_quotes_in_body_for_shell` before committing. Lives in [CurlRenderer](/rendering/curl-renderer.md).
