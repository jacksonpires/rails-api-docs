# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class DocResponderTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("rails-api-docs-resp")
    @path   = File.join(@tmpdir, "rails-api-docs.yml")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def write_minimal_config
    File.write(@path, <<~YAML)
      general_configurations:
        title: My App API
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

  def test_returns_200_and_html_when_config_exists
    write_minimal_config
    status, html = RailsApiDocs::Doc::Responder.new(config_path: @path).render

    assert_equal 200, status
    assert_match(/\A<!DOCTYPE html>/, html)
    assert_match(/My App API/, html)
    assert_match(/List Users/, html)
  end

  def test_returns_404_with_setup_page_when_config_missing
    status, html = RailsApiDocs::Doc::Responder.new(config_path: @path).render

    assert_equal 404, status
    assert_match(/\A<!DOCTYPE html>/, html)
    assert_match(/setup needed/, html)
    assert_match(/rails g rails-api-docs:init/, html)
    assert_match(/#{Regexp.escape(@path)}/, html)
  end

  def test_setup_page_escapes_the_path
    weird_path = File.join(@tmpdir, "<bad>.yml")
    status, html = RailsApiDocs::Doc::Responder.new(config_path: weird_path).render

    assert_equal 404, status
    refute_match(/<bad>\.yml/, html)
    assert_match(/&lt;bad&gt;\.yml/, html)
  end

  def test_reflects_yaml_changes_between_calls
    write_minimal_config
    responder = RailsApiDocs::Doc::Responder.new(config_path: @path)

    _, html1 = responder.render
    assert_match(/List Users/, html1)

    File.write(@path, File.read(@path).sub("List Users", "Renamed Endpoint"))

    _, html2 = responder.render
    assert_match(/Renamed Endpoint/, html2)
    refute_match(/List Users/, html2)
  end
end
