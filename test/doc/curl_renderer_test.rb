# frozen_string_literal: true

require "test_helper"

class CurlRendererTest < Minitest::Test
  def curl_for(endpoint, base_url: "https://api.example.com")
    RailsApiDocs::Doc::CurlRenderer.new(endpoint, base_url: base_url).call
  end

  def test_basic_get_request_has_no_data
    curl = curl_for({ "method" => "GET", "path" => "/users" })

    assert_match(/^curl --request GET \\\n  --url https:\/\/api\.example\.com\/users$/, curl)
    refute_match(/--data/, curl)
    refute_match(/--header/, curl)
  end

  def test_post_with_body_includes_data_and_content_type
    curl = curl_for({
      "method" => "POST", "path" => "/users",
      "body" => [
        { "name" => "email",    "type" => "string",  "required" => true },
        { "name" => "age",      "type" => "integer", "required" => false }
      ]
    })

    assert_match(/curl --request POST \\/, curl)
    assert_match(/--url https:\/\/api\.example\.com\/users \\/, curl)
    assert_match(/--header 'Content-Type: application\/json' \\/, curl)
    assert_match(/--data '\{/, curl)
    assert_match(/"email": "example"/, curl)
    assert_match(/"age": 1/, curl)
  end

  def test_field_example_propagates_into_curl_body
    curl = curl_for({
      "method" => "POST", "path" => "/v1/suppliers",
      "body" => [
        { "name" => "setting_tag_ids", "type" => "string",  "example" => "sss-asdfasd-4qw4ae-qa5" },
        { "name" => "name",            "type" => "string",  "example" => "Acme Corp" },
        { "name" => "tier",            "type" => "integer", "example" => 3 }
      ]
    })

    # Field's own example wins over the type-derived "example" sample.
    assert_match(/"setting_tag_ids": "sss-asdfasd-4qw4ae-qa5"/, curl)
    assert_match(/"name": "Acme Corp"/, curl)
    assert_match(/"tier": 3/, curl)
  end

  def test_field_without_example_still_falls_back_to_type_sample
    curl = curl_for({
      "method" => "POST", "path" => "/users",
      "body" => [{ "name" => "email", "type" => "string" }]
    })
    assert_match(/"email": "example"/, curl)
  end

  def test_uses_request_example_verbatim_when_provided
    curl = curl_for({
      "method" => "POST", "path" => "/users",
      "body" => [{ "name" => "email", "type" => "string" }],
      "request_example" => '{ "user": { "email": "real@example.com" } }'
    })

    assert_match(/real@example\.com/, curl)
    refute_match(/"email": "example"/, curl)
  end

  def test_substitutes_path_params_with_sample_value
    curl = curl_for({
      "method" => "GET", "path" => "/users/:id/posts/:post_id",
      "params" => [
        { "name" => "id",      "type" => "integer", "in" => "path" },
        { "name" => "post_id", "type" => "integer", "in" => "path" }
      ]
    })

    assert_match(/\/users\/1\/posts\/1/, curl)
  end

  def test_honors_param_example_when_provided
    curl = curl_for({
      "method" => "GET", "path" => "/users/:slug",
      "params" => [{ "name" => "slug", "type" => "string", "in" => "path", "example" => "jane-doe" }]
    })

    assert_match(/\/users\/jane-doe/, curl)
  end

  def test_string_path_param_falls_back_to_string_sample
    curl = curl_for({
      "method" => "GET", "path" => "/tags/:name",
      "params" => [{ "name" => "name", "type" => "string", "in" => "path" }]
    })

    assert_match(/\/tags\/example/, curl)
  end

  def test_escapes_single_quotes_in_body_for_shell
    # The standard shell escape for ' inside '...' is the four-char
    # sequence '\'' (close, escaped quote, reopen).
    curl = curl_for({
      "method" => "POST", "path" => "/x",
      "body" => [{ "name" => "note", "type" => "string" }],
      "request_example" => %({ "note": "It's working" })
    })

    assert_includes curl, %q(It'\''s working)
  end

  def test_empty_body_array_does_not_emit_data
    curl = curl_for({ "method" => "POST", "path" => "/x", "body" => [] })
    refute_match(/--data/, curl)
  end

  def test_query_params_do_not_substitute_into_url
    curl = curl_for({
      "method" => "GET", "path" => "/users/:id",
      "params" => [
        { "name" => "id",     "type" => "integer", "in" => "path" },
        { "name" => "filter", "type" => "string",  "in" => "query" }
      ]
    })

    assert_match(/\/users\/1$/, curl.lines.last.strip)
    refute_match(/filter/, curl)
  end

  # ---------------- request headers ----------------

  def test_includes_user_declared_headers
    curl = curl_for({
      "method" => "GET", "path" => "/me",
      "headers" => [
        { "name" => "Authorization",     "type" => "string", "example" => "Bearer xyz" },
        { "name" => "X-Idempotency-Key", "type" => "string", "example" => "abc-123" }
      ]
    })

    assert_match(/--header 'Authorization: Bearer xyz' \\/, curl)
    assert_match(/--header 'X-Idempotency-Key: abc-123'/, curl)
  end

  def test_header_without_example_falls_back_to_type_sample
    curl = curl_for({
      "method" => "GET", "path" => "/me",
      "headers" => [{ "name" => "X-Tenant", "type" => "string" }]
    })

    assert_match(/--header 'X-Tenant: example'/, curl)
  end

  def test_auth_bearer_injects_placeholder_when_no_authorization_header
    curl = curl_for({ "method" => "GET", "path" => "/me", "auth" => "bearer" })
    assert_match(/--header 'Authorization: Bearer YOUR_TOKEN_HERE'/, curl)
  end

  def test_auth_basic_injects_basic_placeholder
    curl = curl_for({ "method" => "GET", "path" => "/me", "auth" => "basic" })
    assert_match(/--header 'Authorization: Basic BASE64_ENCODED_CREDENTIALS'/, curl)
  end

  def test_auth_does_not_overwrite_explicit_authorization_header
    curl = curl_for({
      "method" => "GET", "path" => "/me",
      "auth"   => "bearer",
      "headers" => [{ "name" => "Authorization", "type" => "string", "example" => "Bearer real-token" }]
    })

    assert_match(/Bearer real-token/, curl)
    refute_match(/YOUR_TOKEN_HERE/, curl)
  end

  def test_auth_none_does_not_inject_anything
    curl = curl_for({ "method" => "GET", "path" => "/me", "auth" => "none" })
    refute_match(/Authorization/, curl)
  end

  def test_headers_emitted_before_content_type_and_data
    curl = curl_for({
      "method" => "POST", "path" => "/users",
      "headers" => [{ "name" => "Authorization", "type" => "string", "example" => "Bearer x" }],
      "body" => [{ "name" => "email", "type" => "string" }]
    })

    # Strip trailing backslashes and split by lines, check ordering
    lines       = curl.lines.map(&:strip)
    auth_idx    = lines.index { |l| l.include?("Authorization") }
    content_idx = lines.index { |l| l.include?("Content-Type") }
    data_idx    = lines.index { |l| l.include?("--data") }

    assert auth_idx < content_idx
    assert content_idx < data_idx
  end
end
