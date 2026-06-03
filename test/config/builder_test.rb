# frozen_string_literal: true

require "test_helper"
require "yaml"

class ConfigBuilderTest < Minitest::Test
  def routes_fixture
    [
      { verb: "GET",    path: "/users",      controller: "users", action: "index",   name: "users",  path_params: [] },
      { verb: "POST",   path: "/users",      controller: "users", action: "create",  name: nil,      path_params: [] },
      { verb: "GET",    path: "/users/:id",  controller: "users", action: "show",    name: "user",   path_params: ["id"] },
      { verb: "PATCH",  path: "/users/:id",  controller: "users", action: "update",  name: nil,      path_params: ["id"] },
      { verb: "DELETE", path: "/users/:id",  controller: "users", action: "destroy", name: nil,      path_params: ["id"] },
      { verb: "GET",    path: "/api/v1/posts", controller: "api/v1/posts", action: "index", name: "api_v1_posts", path_params: [] }
    ]
  end

  def test_builds_full_structure_with_general_and_sections
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call

    assert_kind_of Hash, out["general_configurations"]
    assert_equal "#CC0000", out["general_configurations"]["primary_color"]
    assert_equal "#2E2E2E", out["general_configurations"]["secondary_color"]

    assert out["sections"]["users"]
    assert out["sections"]["api/v1/posts"]
  end

  def test_groups_endpoints_by_controller
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call

    users_endpoints = out["sections"]["users"]["endpoints"]
    assert_equal 5, users_endpoints.size

    methods = users_endpoints.map { |e| e["method"] }
    assert_equal %w[GET POST GET PATCH DELETE], methods
  end

  def test_humanizes_section_name_using_last_segment
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call

    assert_equal "Users", out["sections"]["users"]["name"]
    assert_equal "Posts", out["sections"]["api/v1/posts"]["name"]
  end

  def test_generates_endpoint_names_from_action
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call
    by_method = out["sections"]["users"]["endpoints"].each_with_object({}) do |e, acc|
      acc[[e["method"], e["path"]]] = e["name"]
    end

    assert_equal "List Users",   by_method[["GET",    "/users"]]
    assert_equal "Create User",  by_method[["POST",   "/users"]]
    assert_equal "Show User",    by_method[["GET",    "/users/:id"]]
    assert_equal "Update User",  by_method[["PATCH",  "/users/:id"]]
    assert_equal "Delete User",  by_method[["DELETE", "/users/:id"]]
  end

  def test_each_endpoint_defaults_to_show_true_empty_description
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call
    out["sections"].each_value do |section|
      assert section["show"]
      assert_equal "", section["description"]
      section["endpoints"].each do |e|
        assert e["show"]
        assert_equal "", e["description"]
      end
    end
  end

  def test_to_yaml_roundtrips_cleanly
    builder = RailsApiDocs::Config::Builder.new(routes: routes_fixture)
    yaml    = builder.to_yaml
    parsed  = YAML.safe_load(yaml)

    assert_equal builder.call, parsed
  end

  # ============================================================
  # Pragmatic auto-emit (default mode)
  # ============================================================

  def test_path_params_include_description_and_example
    out  = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call
    show = out["sections"]["users"]["endpoints"].find { |e| e["method"] == "GET" && e["path"] == "/users/:id" }

    id_param = show["params"].first
    assert_equal "id",       id_param["name"]
    assert_equal "integer",  id_param["type"]
    assert_equal "",         id_param["description"]
    assert_equal 1,          id_param["example"]
  end

  def test_response_stub_emitted_for_every_endpoint_in_pragmatic_mode
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call
    out["sections"]["users"]["endpoints"].each do |e|
      assert e["responses"], "missing responses stub on #{e['method']} #{e['path']}"
      stub = e["responses"]["200"]
      assert_equal "", stub["description"]
      assert_equal "", stub["example"]
      # Pragmatic stub stays minimal — no headers/schema keys.
      refute stub.key?("headers")
      refute stub.key?("schema")
    end
  end

  def test_pragmatic_mode_omits_verbose_endpoint_metadata
    out      = RailsApiDocs::Config::Builder.new(routes: routes_fixture).call
    endpoint = out["sections"]["users"]["endpoints"].first
    %w[deprecated auth tags headers request_example].each do |k|
      refute endpoint.key?(k), "expected #{k} not emitted in pragmatic mode"
    end
  end

  # ============================================================
  # Verbose mode (--verbose-yaml)
  # ============================================================

  def test_verbose_mode_emits_all_endpoint_metadata
    out      = RailsApiDocs::Config::Builder.new(routes: routes_fixture, verbose: true).call
    endpoint = out["sections"]["users"]["endpoints"].first

    assert_equal false, endpoint["deprecated"]
    assert_equal "",    endpoint["auth"]
    assert_equal [],    endpoint["tags"]
    assert_equal [],    endpoint["headers"]
    assert_equal "",    endpoint["request_example"]
  end

  def test_verbose_mode_emits_empty_params_and_body_when_inference_absent
    # GET /users (index) has no path params and no body inferred.
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture, verbose: true).call
    idx = out["sections"]["users"]["endpoints"].find { |e| e["method"] == "GET" && e["path"] == "/users" }

    assert_equal [], idx["params"]
    assert_equal [], idx["body"]
  end

  def test_verbose_mode_response_stub_has_headers_and_schema
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture, verbose: true).call
    stub = out["sections"]["users"]["endpoints"].first["responses"]["200"]

    assert_equal "", stub["description"]
    assert_equal [], stub["headers"]
    assert_equal [], stub["schema"]
    assert_equal "", stub["example"]
  end

  def test_verbose_mode_path_param_has_all_field_keys
    out  = RailsApiDocs::Config::Builder.new(routes: routes_fixture, verbose: true).call
    show = out["sections"]["users"]["endpoints"].find { |e| e["method"] == "GET" && e["path"] == "/users/:id" }
    p    = show["params"].first

    assert_equal "",    p["format"]
    assert_equal [],    p["enum"]
    assert_nil          p["default"]
    assert_equal false, p["read_only"]
    assert_equal false, p["nullable"]
  end

  def test_verbose_mode_arrays_are_independent_per_endpoint
    # No shared array references across endpoints (otherwise YAML.dump
    # emits noisy &/* anchors).
    out = RailsApiDocs::Config::Builder.new(routes: routes_fixture, verbose: true).call
    a   = out["sections"]["users"]["endpoints"][0]
    b   = out["sections"]["users"]["endpoints"][1]

    refute a["tags"].equal?(b["tags"])
    refute a["headers"].equal?(b["headers"])

    yaml = out.to_yaml
    refute_match(/&\d/, yaml, "YAML output should not contain anchors")
    refute_match(/\*\d/, yaml, "YAML output should not contain alias refs")
  end
end
