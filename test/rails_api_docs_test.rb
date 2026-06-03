# frozen_string_literal: true

require "test_helper"

class RailsApiDocsTest < Minitest::Test
  def test_version_is_defined
    refute_nil ::RailsApiDocs::VERSION
  end

  def test_configuration_defaults
    RailsApiDocs.reset_configuration!
    config = RailsApiDocs.configuration

    assert_equal "config/rails-api-docs.yml", config.config_path
    assert_equal "public/api-docs.html",      config.output_path
    assert_equal "/rails/api-docs",           config.mount_path
    assert config.mount_in_development
  end

  def test_configure_block
    RailsApiDocs.reset_configuration!
    RailsApiDocs.configure do |c|
      c.output_path = "tmp/custom.html"
      c.mount_in_development = false
    end

    assert_equal "tmp/custom.html", RailsApiDocs.configuration.output_path
    refute RailsApiDocs.configuration.mount_in_development
  ensure
    RailsApiDocs.reset_configuration!
  end

  def test_engine_class_is_loaded
    assert defined?(RailsApiDocs::Engine)
    assert RailsApiDocs::Engine < ::Rails::Engine
  end
end
