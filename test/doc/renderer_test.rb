# frozen_string_literal: true

require "test_helper"

class DocRendererTest < Minitest::Test
  def config
    {
      "general_configurations" => {
        "title"           => "My App API",
        "base_url"        => "https://api.example.com",
        "primary_color"   => "#ABCDEF",
        "secondary_color" => "#123456",
        "show_curl"       => true,
        "show_examples"   => true
      },
      "sections" => {
        "users" => {
          "name" => "Users", "description" => "", "show" => true,
          "endpoints" => [
            {
              "method" => "POST", "path" => "/users", "name" => "Create User",
              "description" => "Register a new account.", "show" => true,
              "body" => [
                { "name" => "email", "type" => "string", "required" => true },
                { "name" => "age",   "type" => "integer", "required" => false }
              ]
            },
            {
              "method" => "GET", "path" => "/users/:id", "name" => "Show User",
              "description" => "", "show" => true,
              "params" => [{ "name" => "id", "type" => "integer", "required" => true, "in" => "path" }]
            }
          ]
        },
        "hidden_section" => {
          "name" => "Hidden", "show" => false,
          "endpoints" => [{ "method" => "GET", "path" => "/hidden", "name" => "Nope", "show" => true }]
        }
      }
    }
  end

  def html
    @html ||= RailsApiDocs::Doc::Renderer.new(config).call
  end

  def test_emits_full_html_document
    assert_match(/\A<!DOCTYPE html>/, html)
    assert_match(/<\/html>\s*\z/, html)
  end

  def test_injects_css_variables_from_general_configurations
    assert_match(/--primary:\s*#ABCDEF/, html)
    assert_match(/--secondary:\s*#123456/, html)
  end

  def test_sets_document_title
    assert_match(/<title>My App API<\/title>/, html)
  end

  def test_sidebar_contains_visible_sections_and_endpoints
    assert_match(/data-section="users"/, html)
    assert_match(/Create User/, html)
    assert_match(/Show User/, html)
  end

  def test_omits_sections_with_show_false
    refute_match(/data-section="hidden_section"/, html)
    refute_match(/>Nope</, html)
  end

  def test_omits_endpoints_with_show_false
    cfg = {
      "sections" => {
        "users" => {
          "name" => "Users", "show" => true,
          "endpoints" => [
            { "method" => "GET", "path" => "/users", "name" => "Visible", "show" => true },
            { "method" => "POST", "path" => "/users", "name" => "Hidden",  "show" => false }
          ]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    assert_match(/Visible/, out)
    refute_match(/>Hidden</, out)
  end

  def test_renders_endpoint_pages_for_each_visible_endpoint
    pages = html.scan(/class="endpoint-page"/).size
    assert_equal 2, pages
  end

  def test_only_one_endpoint_is_active_at_load_time
    # The active class is only added client-side by JS, so server-rendered
    # markup has zero active pages.
    active_count = html.scan(/class="endpoint-page active"/).size
    assert_equal 0, active_count
  end

  def test_renders_body_fields_with_required_badge
    assert_match(/<span class="field-name">email<\/span>/, html)
    assert_match(/<span class="field-badge required">Required<\/span>/, html)
  end

  def test_renders_path_params
    assert_match(/<span class="field-name">id<\/span>/, html)
    assert_match(/<span class="field-badge in-path">path<\/span>/, html)
  end

  def test_renders_curl_block_with_base_url
    assert_match(/curl --request POST/, html)
    assert_match(/https:\/\/api\.example\.com\/users/, html)
  end

  def test_curl_includes_body_data_when_body_present
    # Curl is rendered inside <pre>, so quotes are HTML-entity-escaped.
    assert_match(/--data &#39;\{/, html)
    assert_match(/&quot;email&quot;: &quot;example&quot;/, html)
  end

  def test_curl_substitutes_path_params_with_sample_value
    assert_match(/https:\/\/api\.example\.com\/users\/1/, html)
  end

  def test_renders_single_response_block_by_default
    # When no `responses:` map is in YAML, fallback to a single "200" tab.
    assert_match(/data-resp-status="200"/, html)
    assert_match(/data-resp-body="200"/, html)
  end

  def test_field_example_propagates_into_default_response_body
    cfg = {
      "sections" => {
        "x" => {
          "name" => "X", "show" => true,
          "endpoints" => [{
            "method" => "POST", "path" => "/x", "name" => "Try", "show" => true,
            "body" => [
              { "name" => "setting_tag_ids", "type" => "string", "example" => "sss-asdfasd-4qw4ae-qa5" }
            ]
          }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call
    # Response example synthesized from body should use field["example"].
    assert_match(/&quot;setting_tag_ids&quot;: &quot;sss-asdfasd-4qw4ae-qa5&quot;/, out)
  end

  def test_renders_multiple_response_tabs_when_responses_provided
    cfg = {
      "sections" => {
        "users" => {
          "name" => "Users", "show" => true,
          "endpoints" => [{
            "method" => "POST", "path" => "/users", "name" => "Create User", "show" => true,
            "responses" => {
              "201" => { "description" => "Created", "example" => '{ "id": 1 }' },
              "422" => { "description" => "Validation failed", "example" => '{ "errors": [] }' }
            }
          }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    assert_match(/data-resp-status="201"/, out)
    assert_match(/data-resp-status="422"/, out)
    assert_match(/data-resp-body="201"/, out)
    assert_match(/data-resp-body="422"/, out)
    # First tab should be active, others not
    assert_match(/<span class="response-tab [^"]*active"[^>]*data-resp-status="201"/, out)
    refute_match(/<span class="response-tab [^"]*active"[^>]*data-resp-status="422"/, out)
    # Examples present
    assert_match(/&quot;id&quot;: 1/, out)
    assert_match(/&quot;errors&quot;: \[\]/, out)
  end

  def test_response_tab_uses_status_class
    cfg = {
      "sections" => {
        "x" => {
          "name" => "X", "show" => true,
          "endpoints" => [{
            "method" => "POST", "path" => "/x", "name" => "Try", "show" => true,
            "responses" => {
              "201" => { "example" => "{}" },
              "422" => { "example" => "{}" },
              "500" => { "example" => "{}" }
            }
          }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    assert_match(/<span class="response-tab status-2xx[^"]*"[^>]*data-resp-status="201"/, out)
    assert_match(/<span class="response-tab status-4xx[^"]*"[^>]*data-resp-status="422"/, out)
    assert_match(/<span class="response-tab status-5xx[^"]*"[^>]*data-resp-status="500"/, out)
  end

  def test_escapes_user_provided_html_in_descriptions
    cfg = {
      "sections" => {
        "x" => {
          "name" => "X", "show" => true,
          "endpoints" => [{
            "method" => "GET", "path" => "/x", "name" => "Evil",
            "description" => "<script>alert(1)</script>", "show" => true
          }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    refute_match(/<script>alert/, out)
    assert_match(/&lt;script&gt;alert/, out)
  end

  def test_empty_state_when_no_visible_sections
    out = RailsApiDocs::Doc::Renderer.new("sections" => {}).call
    assert_match(/No endpoints to show/, out)
  end

  # ============================================================
  # Field-level richness (Tier 1)
  # ============================================================

  def render_with_endpoint(endpoint)
    cfg = {
      "sections" => {
        "x" => {
          "name" => "X", "show" => true,
          "endpoints" => [endpoint.merge("method" => endpoint["method"] || "POST",
                                         "path"   => endpoint["path"]   || "/x",
                                         "name"   => endpoint["name"]   || "Try",
                                         "show"   => true)]
        }
      }
    }
    RailsApiDocs::Doc::Renderer.new(cfg).call
  end

  def test_field_renders_format_badge
    out = render_with_endpoint(
      "body" => [{ "name" => "email", "type" => "string", "format" => "email" }]
    )
    assert_match(/<span class="field-badge format">email<\/span>/, out)
  end

  def test_field_renders_enum_as_pipe_list
    out = render_with_endpoint(
      "body" => [{ "name" => "role", "type" => "string", "enum" => %w[user admin guest] }]
    )
    assert_match(/<div class="field-enum">one of: /, out)
    assert_match(/<code>user<\/code>/, out)
    assert_match(/<code>admin<\/code>/, out)
    assert_match(/<code>guest<\/code>/, out)
  end

  def test_field_renders_default_value
    out = render_with_endpoint(
      "body" => [{ "name" => "role", "type" => "string", "default" => "user" }]
    )
    assert_match(/<span class="field-meta">default: user<\/span>/, out)
  end

  def test_field_renders_default_when_value_is_false
    # `unless default.nil?` — boolean false should still render.
    out = render_with_endpoint(
      "body" => [{ "name" => "admin", "type" => "boolean", "default" => false }]
    )
    assert_match(/default: false/, out)
  end

  def test_field_renders_min_and_max_constraints
    out = render_with_endpoint(
      "body" => [{ "name" => "password", "type" => "string", "min_length" => 8, "max_length" => 72 }]
    )
    assert_match(/min: 8/, out)
    assert_match(/max: 72/, out)
  end

  def test_field_renders_pattern_constraint
    out = render_with_endpoint(
      "body" => [{ "name" => "zip", "type" => "string", "pattern" => "^\\d{5}$" }]
    )
    assert_match(/pattern: \^\\d\{5\}\$/, out)
  end

  def test_field_renders_read_only_and_write_only_badges
    out = render_with_endpoint(
      "body" => [
        { "name" => "id",       "type" => "integer", "read_only"  => true },
        { "name" => "password", "type" => "string",  "write_only" => true }
      ]
    )
    assert_match(/<span class="field-badge readonly">read-only<\/span>/, out)
    assert_match(/<span class="field-badge writeonly">write-only<\/span>/, out)
  end

  def test_field_renders_nullable_badge
    out = render_with_endpoint(
      "body" => [{ "name" => "deleted_at", "type" => "datetime", "nullable" => true }]
    )
    assert_match(/<span class="field-badge nullable">nullable<\/span>/, out)
  end

  def test_field_renders_inline_example_below_description
    out = render_with_endpoint(
      "body" => [{ "name" => "email", "type" => "string", "description" => "Unique", "example" => "marc@example.com" }]
    )
    assert_match(/<div class="field-desc">Unique<\/div>/, out)
    assert_match(/<div class="field-example">Example: <code>marc@example\.com<\/code><\/div>/, out)
  end

  # ============================================================
  # Request headers (Tier 2)
  # ============================================================

  def test_request_headers_section_rendered
    out = render_with_endpoint(
      "headers" => [
        { "name" => "Authorization",     "type" => "string", "required" => true, "description" => "Bearer token" },
        { "name" => "X-Idempotency-Key", "type" => "string", "required" => false }
      ]
    )
    assert_match(/<h2>Headers<\/h2>/, out)
    assert_match(/<span class="field-name">Authorization<\/span>/, out)
    assert_match(/<span class="field-name">X-Idempotency-Key<\/span>/, out)
    assert_match(/Bearer token/, out)
  end

  def test_no_headers_section_when_absent
    out = render_with_endpoint("body" => [{ "name" => "x", "type" => "string" }])
    refute_match(/<h2>Headers<\/h2>/, out)
  end

  # ============================================================
  # Response headers + schema (Tier 2)
  # ============================================================

  def test_response_block_renders_in_central_column_when_headers_or_schema_present
    out = render_with_endpoint(
      "responses" => {
        "201" => {
          "description" => "Created",
          "headers" => [{ "name" => "Location", "type" => "string", "example" => "/users/42" }],
          "schema"  => [
            { "name" => "id",    "type" => "integer", "example" => 42 },
            { "name" => "email", "type" => "string",  "format" => "email" }
          ],
          "example" => '{ "id": 42 }'
        }
      }
    )
    # Section heading
    assert_match(/<h2>Responses<\/h2>/, out)
    # Status badge and description
    assert_match(/<span class="response-status status-2xx">201<\/span>/, out)
    assert_match(/<span class="response-block-desc">Created<\/span>/, out)
    # Subheads
    assert_match(/<h3 class="response-subhead">Headers<\/h3>/, out)
    assert_match(/<h3 class="response-subhead">Schema<\/h3>/, out)
    # Headers field rendered
    assert_match(/<span class="field-name">Location<\/span>/, out)
    # Schema fields rendered
    assert_match(/<span class="field-name">id<\/span>/, out)
    assert_match(/<span class="field-name">email<\/span>/, out)
    assert_match(/<span class="field-badge format">email<\/span>/, out)
  end

  def test_responses_central_column_omitted_when_no_details
    # Bare responses with only example → only the right-column tab, no central block.
    out = render_with_endpoint(
      "responses" => { "200" => { "example" => '{}' } }
    )
    refute_match(/<h2>Responses<\/h2>/, out)
    # But the right-column tab is still present
    assert_match(/data-resp-status="200"/, out)
  end

  # ============================================================
  # Endpoint metadata (Tier 3)
  # ============================================================

  def test_deprecated_endpoint_renders_badge_and_strikethrough_heading
    out = render_with_endpoint("name" => "Old Thing", "deprecated" => true)
    assert_match(/<span class="endpoint-meta deprecated">Deprecated<\/span>/, out)
    assert_match(/<h1 class="deprecated">Old Thing<\/h1>/, out)
  end

  def test_auth_renders_label_badge
    out = render_with_endpoint("auth" => "bearer")
    assert_match(/<span class="endpoint-meta auth">.+Bearer auth/, out)
  end

  def test_auth_custom_string_rendered_verbatim
    out = render_with_endpoint("auth" => "OAuth2")
    assert_match(/<span class="endpoint-meta auth">.+OAuth2/, out)
  end

  def test_tags_render_as_clickable_buttons
    out = render_with_endpoint("tags" => %w[public auth])
    # Tags are now <button> elements (clickable, accessible) carrying
    # data-tag-filter so the sidebar JS can wire them up.
    assert_match(/<button type="button" class="endpoint-meta tag" data-tag-filter="public"[^>]*>public<\/button>/, out)
    assert_match(/<button type="button" class="endpoint-meta tag" data-tag-filter="auth"[^>]*>auth<\/button>/, out)
  end

  def test_tag_buttons_start_inactive_via_aria_pressed
    out = render_with_endpoint("tags" => ["beta"])
    assert_match(/data-tag-filter="beta"[^>]*aria-pressed="false"/, out)
  end

  def test_no_meta_section_when_absent
    out = render_with_endpoint({})
    refute_match(/<span class="endpoint-meta/, out)
    refute_match(/<h1 class="deprecated"/, out)
  end

  # ============================================================
  # Copy buttons + Response title (right column)
  # ============================================================

  def test_curl_box_has_copy_button
    out = html
    # Two endpoints in the fixture, so two curl copy buttons.
    copy_count = out.scan(/<button[^>]*class="copy-btn"[^>]*aria-label="Copy to clipboard"/).size
    assert copy_count >= 2, "expected at least one curl + one response copy button per endpoint"
  end

  def test_copy_button_contains_both_copy_and_check_icons
    out = html
    assert_match(/<svg class="copy-icon"/, out)
    assert_match(/<svg class="check-icon"/, out)
  end

  def test_response_box_has_title_label
    out = html
    assert_match(/<span class="response-title">Response<\/span>/, out)
  end

  def test_copy_buttons_have_accessible_label
    out = html
    assert_match(/aria-label="Copy to clipboard"/, out)
  end

  def test_response_header_appears_above_tabs
    out = html
    # The "Response" title should appear in the source BEFORE the first response-tab.
    title_idx = out.index('class="response-title"')
    tab_idx   = out.index('class="response-tab')
    assert title_idx
    assert tab_idx
    assert title_idx < tab_idx, "Response title must precede response tabs in DOM order"
  end

  def test_copy_button_inline_javascript_present
    out = html
    # Sanity check the JS wiring is emitted (so the button does something).
    assert_match(/getCopyText/, out)
    assert_match(/navigator\.clipboard/, out)
    assert_match(/document\.execCommand\('copy'\)/, out)
  end

  # ============================================================
  # Tag click filter (sidebar)
  # ============================================================

  def test_sidebar_li_has_endpoint_tags_attribute_when_tags_present
    cfg = {
      "sections" => {
        "users" => {
          "name" => "Users", "show" => true,
          "endpoints" => [{
            "method" => "POST", "path" => "/users", "name" => "Create User",
            "show" => true, "tags" => %w[public auth]
          }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    # JSON-encoded array, escaped for HTML attribute context.
    assert_match(/data-endpoint-tags='\[&quot;public&quot;,&quot;auth&quot;\]'/, out)
  end

  def test_sidebar_li_omits_tags_attribute_when_no_tags
    cfg = {
      "sections" => {
        "users" => {
          "name" => "Users", "show" => true,
          "endpoints" => [{ "method" => "GET", "path" => "/users", "name" => "List", "show" => true }]
        }
      }
    }
    out = RailsApiDocs::Doc::Renderer.new(cfg).call

    refute_match(/data-endpoint-tags/, out)
  end

  def test_active_tag_filter_pill_emitted_hidden_by_default
    out = html
    assert_match(/<div class="active-tag-filter" id="rad-active-tag-filter" hidden>/, out)
    assert_match(/<span class="label">Filtered by:<\/span>/, out)
    assert_match(/<button type="button" class="clear-filter"[^>]*>×<\/button>/, out)
  end

  def test_tag_filter_javascript_is_wired
    out = html
    # Sanity check: the unified filter function + state are emitted.
    assert_match(/let activeTag\s*=\s*null/, out)
    assert_match(/function setTagFilter\(tag\)/, out)
    assert_match(/function applyFilters\(\)/, out)
    # Combined filter (search AND tag).
    assert_match(/matchesSearch && matchesTag/, out)
  end
end
