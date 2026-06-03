# frozen_string_literal: true

module RailsApiDocs
  module Config
    # Append-only merge between an existing parsed config and a freshly
    # generated one.
    #
    # Rules:
    #   - Endpoint identity = "#{method} #{path}".
    #   - Existing endpoints win on every field (user edits are sacred).
    #   - New endpoints (not in existing) are appended to their section's
    #     `endpoints` array in the order returned by RouteInspector.
    #   - Brand-new sections are appended at the end of `sections`.
    #   - `general_configurations`: existing keys win; only missing keys
    #     are filled in from the generated defaults — so a new gem version
    #     introducing a new option doesn't force a manual edit.
    class Appender
      def initialize(existing:, generated:)
        @existing  = existing  || {}
        @generated = generated || {}
      end

      def call
        {
          "general_configurations" => merge_general,
          "sections"               => merge_sections
        }
      end

      # { new_sections: [keys...], new_endpoints_by_section: { key => [endpoints...] } }
      def diff
        {
          new_sections: new_section_keys,
          new_endpoints_by_section: new_endpoints_by_section
        }
      end

      def changes?
        d = diff
        !d[:new_sections].empty? || !d[:new_endpoints_by_section].empty?
      end

      private

      def merge_general
        existing  = @existing["general_configurations"]  || {}
        generated = @generated["general_configurations"] || {}
        generated.merge(existing)
      end

      def merge_sections
        existing  = @existing["sections"]  || {}
        generated = @generated["sections"] || {}

        merged = existing.dup

        generated.each do |key, gen_section|
          merged[key] = merged.key?(key) ? merge_section(merged[key], gen_section) : gen_section
        end

        merged
      end

      def merge_section(existing_section, generated_section)
        existing_endpoints  = existing_section["endpoints"]  || []
        generated_endpoints = generated_section["endpoints"] || []

        existing_keys = existing_endpoints.map { |e| endpoint_key(e) }
        new_only      = generated_endpoints.reject { |e| existing_keys.include?(endpoint_key(e)) }

        existing_section.merge("endpoints" => existing_endpoints + new_only)
      end

      def endpoint_key(endpoint)
        "#{endpoint['method']} #{endpoint['path']}"
      end

      def new_section_keys
        existing_keys  = (@existing["sections"]  || {}).keys
        generated_keys = (@generated["sections"] || {}).keys
        generated_keys - existing_keys
      end

      def new_endpoints_by_section
        result = {}
        (@generated["sections"] || {}).each do |section_key, gen_section|
          existing_section = @existing.dig("sections", section_key)
          next unless existing_section

          existing_keys = (existing_section["endpoints"] || []).map { |e| endpoint_key(e) }
          new_endpoints = (gen_section["endpoints"] || []).reject { |e| existing_keys.include?(endpoint_key(e)) }
          result[section_key] = new_endpoints unless new_endpoints.empty?
        end
        result
      end
    end
  end
end
