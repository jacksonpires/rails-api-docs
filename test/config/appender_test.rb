# frozen_string_literal: true

require "test_helper"

class ConfigAppenderTest < Minitest::Test
  def existing_config
    {
      "general_configurations" => {
        "primary_color"   => "#FF00FF",        # user changed this
        "secondary_color" => "#2E2E2E",
        "title"           => "My App API"
      },
      "sections" => {
        "users" => {
          "name"        => "Users",
          "description" => "User-edited description",
          "show"        => true,
          "endpoints"   => [
            {
              "method"      => "POST",
              "path"        => "/users",
              "name"        => "Create User",
              "description" => "User-edited endpoint description",
              "show"        => true,
              "body"        => [{ "name" => "email", "type" => "string", "required" => true }]
            }
          ]
        }
      }
    }
  end

  def generated_config
    {
      "general_configurations" => {
        "primary_color"   => "#CC0000",        # gem default
        "secondary_color" => "#2E2E2E",
        "title"           => "API Documentation",
        "show_curl"       => true              # NEW key introduced by gem upgrade
      },
      "sections" => {
        "users" => {
          "name"        => "Users",
          "description" => "",
          "show"        => true,
          "endpoints"   => [
            {
              "method" => "POST", "path" => "/users", "name" => "Create User",
              "description" => "", "show" => true                       # already in existing
            },
            {
              "method" => "GET", "path" => "/users/:id", "name" => "Show User",
              "description" => "", "show" => true                       # NEW
            }
          ]
        },
        "comments" => {                                                  # NEW SECTION
          "name" => "Comments", "description" => "", "show" => true,
          "endpoints" => [
            { "method" => "GET",  "path" => "/comments", "name" => "List Comments",   "description" => "", "show" => true },
            { "method" => "POST", "path" => "/comments", "name" => "Create Comment", "description" => "", "show" => true }
          ]
        }
      }
    }
  end

  def test_existing_general_configurations_win
    merged = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call

    assert_equal "#FF00FF",   merged["general_configurations"]["primary_color"]
    assert_equal "My App API", merged["general_configurations"]["title"]
  end

  def test_new_general_configuration_keys_are_filled_in
    merged = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call

    assert_equal true, merged["general_configurations"]["show_curl"]
  end

  def test_existing_endpoint_fields_are_preserved_verbatim
    merged   = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call
    post     = merged["sections"]["users"]["endpoints"].find { |e| e["method"] == "POST" }

    assert_equal "User-edited endpoint description", post["description"]
    assert_equal "email", post.dig("body", 0, "name")
  end

  def test_new_endpoints_are_appended_to_existing_section
    merged = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call
    users  = merged["sections"]["users"]["endpoints"]

    assert_equal 2, users.size
    assert_equal ["POST", "/users"],     [users[0]["method"], users[0]["path"]]
    assert_equal ["GET",  "/users/:id"], [users[1]["method"], users[1]["path"]]
  end

  def test_new_sections_are_appended_at_the_end
    merged = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call

    assert_equal %w[users comments], merged["sections"].keys
  end

  def test_existing_section_metadata_preserved
    merged = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config).call

    assert_equal "User-edited description", merged["sections"]["users"]["description"]
  end

  def test_diff_reports_new_sections_and_endpoints
    appender = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config)
    d        = appender.diff

    assert_equal ["comments"], d[:new_sections]
    assert_equal ["users"],    d[:new_endpoints_by_section].keys
    assert_equal 1,            d[:new_endpoints_by_section]["users"].size
    assert_equal "GET",        d[:new_endpoints_by_section]["users"].first["method"]
    assert d[:new_endpoints_by_section]["users"].first["path"] == "/users/:id"
  end

  def test_changes_predicate
    appender_with_changes = RailsApiDocs::Config::Appender.new(existing: existing_config, generated: generated_config)
    assert appender_with_changes.changes?

    same      = generated_config
    no_change = RailsApiDocs::Config::Appender.new(existing: same, generated: same)
    refute no_change.changes?
  end
end
