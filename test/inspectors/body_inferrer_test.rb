# frozen_string_literal: true

require "test_helper"

class BodyInferrerTest < Minitest::Test
  class FakeControllerInspector
    def initialize(controller:, root:)
      @controller = controller
    end

    def call
      case @controller
      when "users" then %w[name email password age]
      when "posts" then %w[title body]
      else []
      end
    end
  end

  class FakeSchemaInspector
    def initialize(controller:)
      @controller = controller
    end

    def call
      case @controller
      when "users"
        {
          "name"     => { type: :string,  null: false, default: nil },
          "email"    => { type: :string,  null: false, default: nil },
          "password" => { type: :string,  null: false, default: nil },
          "age"      => { type: :integer, null: true,  default: nil }
        }
      else
        {}
      end
    end
  end

  def inferrer
    RailsApiDocs::Inspectors::BodyInferrer.new(
      controller_inspector: FakeControllerInspector,
      schema_inspector:     FakeSchemaInspector
    )
  end

  def test_returns_typed_body_for_create_action
    body = inferrer.call(controller: "users", action: "create")
    by_name = body.each_with_object({}) { |f, h| h[f["name"]] = f }

    assert_equal "string",  by_name["email"]["type"]
    assert_equal true,      by_name["email"]["required"]
    assert_equal "integer", by_name["age"]["type"]
    assert_equal false,     by_name["age"]["required"]
  end

  def test_returns_typed_body_for_update_action
    refute_nil inferrer.call(controller: "users", action: "update")
  end

  def test_returns_nil_for_read_actions
    assert_nil inferrer.call(controller: "users", action: "index")
    assert_nil inferrer.call(controller: "users", action: "show")
  end

  def test_returns_nil_when_controller_has_no_permits
    assert_nil inferrer.call(controller: "unknown", action: "create")
  end

  def test_falls_back_to_string_when_schema_lacks_a_column
    body = inferrer.call(controller: "posts", action: "create")  # schema is {} for posts
    body.each { |f| assert_equal "string", f["type"] }
    body.each { |f| refute f["required"] }
  end

  def test_pragmatic_mode_adds_description_and_example_to_every_field
    body = inferrer.call(controller: "users", action: "create")
    by_name = body.each_with_object({}) { |f, h| h[f["name"]] = f }

    %w[name email password age].each do |key|
      field = by_name[key]
      assert field.key?("description"), "missing description on #{key}"
      assert_equal "", field["description"]
      assert field.key?("example"),     "missing example on #{key}"
    end

    # Example uses type-derived sample
    assert_equal "example", by_name["name"]["example"]
    assert_equal 1,         by_name["age"]["example"]
  end

  def test_pragmatic_mode_omits_advanced_keys
    body = inferrer.call(controller: "users", action: "create")
    %w[format enum default min max min_length max_length pattern read_only write_only nullable].each do |k|
      refute body.first.key?(k), "expected #{k} not to be emitted in pragmatic mode"
    end
  end

  def test_verbose_mode_emits_all_field_keys_with_defaults
    verbose = RailsApiDocs::Inspectors::BodyInferrer.new(
      controller_inspector: FakeControllerInspector,
      schema_inspector:     FakeSchemaInspector,
      verbose:              true
    )
    body = verbose.call(controller: "users", action: "create")
    field = body.first

    assert_equal "",    field["format"]
    assert_equal [],    field["enum"]
    assert_nil          field["default"]
    assert_nil          field["min"]
    assert_nil          field["max"]
    assert_nil          field["min_length"]
    assert_nil          field["max_length"]
    assert_equal "",    field["pattern"]
    assert_equal false, field["read_only"]
    assert_equal false, field["write_only"]
    assert_equal false, field["nullable"]
  end

  def test_verbose_mode_array_defaults_are_independent_per_field
    verbose = RailsApiDocs::Inspectors::BodyInferrer.new(
      controller_inspector: FakeControllerInspector,
      schema_inspector:     FakeSchemaInspector,
      verbose:              true
    )
    body = verbose.call(controller: "users", action: "create")

    # The empty `enum` arrays must not share an underlying object (would
    # produce noisy YAML anchors otherwise).
    refute body[0]["enum"].equal?(body[1]["enum"])
  end

  def test_caches_inspectors_per_controller
    # Wrap each fake inspector to count instantiations.
    counters = Hash.new(0)

    fake_ci = Class.new(FakeControllerInspector) do
      define_method(:initialize) { |controller:, root:| counters[[:ci, controller]] += 1; super(controller: controller, root: root) }
    end
    fake_si = Class.new(FakeSchemaInspector) do
      define_method(:initialize) { |controller:| counters[[:si, controller]] += 1; super(controller: controller) }
    end

    inferrer = RailsApiDocs::Inspectors::BodyInferrer.new(
      controller_inspector: fake_ci, schema_inspector: fake_si
    )

    3.times { inferrer.call(controller: "users", action: "create") }
    assert_equal 1, counters[[:ci, "users"]]
    assert_equal 1, counters[[:si, "users"]]
  end
end
