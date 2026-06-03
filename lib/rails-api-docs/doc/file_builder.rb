# frozen_string_literal: true

require "fileutils"

module RailsApiDocs
  module Doc
    # Reads the YAML config and writes the rendered HTML to disk.
    # Used by `rake rails-api-docs:build`. Extracted as a service so the
    # rake task body can stay tiny and the build flow is unit-testable.
    class FileBuilder
      class MissingConfigError < StandardError; end

      def initialize(config_path:, output_path:)
        @config_path = config_path
        @output_path = output_path
      end

      # Writes the HTML and returns the absolute output path.
      def call
        unless File.exist?(@config_path)
          raise MissingConfigError,
                "Config file not found at #{@config_path}. " \
                "Run `rails g rails-api-docs:init` first."
        end

        config = Config::Loader.load(@config_path)
        html   = Renderer.new(config).call

        FileUtils.mkdir_p(File.dirname(@output_path))
        File.write(@output_path, html)

        @output_path
      end
    end
  end
end
