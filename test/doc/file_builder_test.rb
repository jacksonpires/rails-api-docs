# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class DocFileBuilderTest < Minitest::Test
  def setup
    @tmpdir      = Dir.mktmpdir("rails-api-docs-fb")
    @config_path = File.join(@tmpdir, "config", "rails-api-docs.yml")
    @output_path = File.join(@tmpdir, "public", "api-docs.html")
    FileUtils.mkdir_p(File.dirname(@config_path))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def write_config
    File.write(@config_path, <<~YAML)
      general_configurations:
        title: Test API
        primary_color: "#CC0000"
        secondary_color: "#2E2E2E"
      sections:
        users:
          name: Users
          show: true
          endpoints:
            - method: GET
              path: /users
              name: List Users
              show: true
    YAML
  end

  def test_writes_html_to_output_path
    write_config
    written = RailsApiDocs::Doc::FileBuilder.new(
      config_path: @config_path, output_path: @output_path
    ).call

    assert_equal @output_path, written
    assert File.exist?(@output_path)

    html = File.read(@output_path)
    assert_match(/\A<!DOCTYPE html>/, html)
    assert_match(/Test API/, html)
    assert_match(/List Users/, html)
  end

  def test_creates_output_directory_when_missing
    write_config
    refute Dir.exist?(File.dirname(@output_path))

    RailsApiDocs::Doc::FileBuilder.new(
      config_path: @config_path, output_path: @output_path
    ).call

    assert Dir.exist?(File.dirname(@output_path))
  end

  def test_raises_with_helpful_message_when_config_missing
    error = assert_raises(RailsApiDocs::Doc::FileBuilder::MissingConfigError) do
      RailsApiDocs::Doc::FileBuilder.new(
        config_path: @config_path, output_path: @output_path
      ).call
    end

    assert_match(/Config file not found/, error.message)
    assert_match(/rails g rails-api-docs:init/, error.message)
  end

  def test_overwrites_existing_output
    write_config
    FileUtils.mkdir_p(File.dirname(@output_path))
    File.write(@output_path, "old garbage content")

    RailsApiDocs::Doc::FileBuilder.new(
      config_path: @config_path, output_path: @output_path
    ).call

    refute_match(/old garbage content/, File.read(@output_path))
    assert_match(/<!DOCTYPE html>/, File.read(@output_path))
  end
end
