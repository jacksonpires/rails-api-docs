# frozen_string_literal: true

require "yaml"

module RailsApiDocs
  module Config
    module Loader
      module_function

      def load(path)
        return {} unless File.exist?(path)

        raw = File.read(path)
        YAML.safe_load(raw, permitted_classes: [Symbol, Date, Time]) || {}
      end

      # Returns the leading comment block ("#"-prefixed lines and blank lines
      # at the top of the file). Used to preserve the auto-generated header
      # — and any user notes they tacked at the top — across re-runs.
      def header(path)
        return "" unless File.exist?(path)

        File.read(path)
            .lines
            .take_while { |line| line.start_with?("#") || line.strip.empty? }
            .join
      end
    end
  end
end
