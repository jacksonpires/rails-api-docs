# frozen_string_literal: true

require "test_helper"
require "action_dispatch"
require "yaml"

# UpdateGenerator is a thin alias of InitGenerator — same behavior, just a
# friendlier name for re-runs. These tests verify the alias is wired up
# correctly and produces identical output to its parent for the same input.
class UpdateGeneratorTest < Rails::Generators::TestCase
  tests RailsApiDocs::Generators::UpdateGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def setup
    super
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      resources :users, only: [:index, :show, :create]
    end
    RailsApiDocs.configuration.route_source = @routes
  end

  def teardown
    super
    RailsApiDocs.reset_configuration!
  end

  def test_update_is_a_subclass_of_init
    assert RailsApiDocs::Generators::UpdateGenerator < RailsApiDocs::Generators::InitGenerator
  end

  def test_update_namespace_is_hyphenated
    assert_equal "rails-api-docs:update", RailsApiDocs::Generators::UpdateGenerator.namespace
  end

  def test_update_creates_yaml_when_file_missing
    run_generator
    assert_file "config/rails-api-docs.yml"
  end

  def test_update_produces_same_yaml_as_init_for_same_input
    # Run UpdateGenerator into our destination
    run_generator
    update_yaml = File.read(File.join(destination_root, "config/rails-api-docs.yml"))

    # Re-prepare and run InitGenerator into the same destination
    prepare_destination
    Rails::Generators.invoke "rails-api-docs:init", [], destination_root: destination_root
    init_yaml = File.read(File.join(destination_root, "config/rails-api-docs.yml"))

    assert_equal init_yaml, update_yaml
  end

  def test_update_inherits_api_only_and_only_controllers_flags
    # Both class_options are inherited from InitGenerator. Sanity-check
    # that invoking with the flags doesn't blow up.
    run_generator ["--only-controllers", "users"]

    yaml = YAML.safe_load(File.read(File.join(destination_root, "config/rails-api-docs.yml")))
    assert_equal ["users"], yaml["sections"].keys
  end
end
