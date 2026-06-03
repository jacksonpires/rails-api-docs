# frozen_string_literal: true

require "test_helper"

class SchemaInspectorTest < Minitest::Test
  FakeColumn = Struct.new(:type, :null, :default)

  class FakeUser
    def self.columns_hash
      {
        "id"         => FakeColumn.new(:integer, false, nil),
        "email"      => FakeColumn.new(:string,  false, nil),
        "name"       => FakeColumn.new(:string,  true,  nil),
        "admin"      => FakeColumn.new(:boolean, false, false),
        "created_at" => FakeColumn.new(:datetime, false, nil)
      }
    end
  end

  def inspect_controller(controller, model:)
    RailsApiDocs::Inspectors::SchemaInspector.new(
      controller: controller,
      model_resolver: ->(_) { model }
    ).call
  end

  def test_returns_typed_column_metadata
    result = inspect_controller("users", model: FakeUser)

    assert_equal :string,  result["email"][:type]
    assert_equal false,    result["email"][:null]
    assert_nil   result["email"][:default]

    assert_equal :boolean, result["admin"][:type]
    assert_equal false,    result["admin"][:default]
  end

  def test_returns_empty_when_model_resolver_returns_nil
    assert_empty inspect_controller("nonexistent", model: nil)
  end

  def test_returns_empty_when_model_does_not_respond_to_columns_hash
    bare = Class.new
    assert_empty inspect_controller("anything", model: bare)
  end

  def test_swallows_resolver_errors
    raising = ->(_) { raise "boom" }
    result  = RailsApiDocs::Inspectors::SchemaInspector.new(
      controller: "users", model_resolver: raising
    ).call

    assert_empty result
  end

  def test_default_resolver_finds_top_level_constants
    Object.const_set(:RaildApiDocsTestModel, Class.new {
      def self.columns_hash
        { "x" => FakeColumn.new(:string, true, nil) }
      end
    })

    # last segment of controller path → singularize → camelize
    # so "raild_api_docs_test_models" -> "RaildApiDocsTestModel"
    result = RailsApiDocs::Inspectors::SchemaInspector.new(
      controller: "raild_api_docs_test_models"
    ).call

    assert_equal :string, result["x"][:type]
  ensure
    Object.send(:remove_const, :RaildApiDocsTestModel) if Object.const_defined?(:RaildApiDocsTestModel)
  end
end
