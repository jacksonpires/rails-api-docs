# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/string/inflections"

module RailsApiDocs
  module Config
    # Turns the array of route hashes produced by RouteInspector into the
    # full config structure that gets written to config/rails-api-docs.yml.
    #
    # Output shape:
    #   {
    #     "general_configurations" => { ... defaults ... },
    #     "sections" => {
    #       "<controller_key>" => {
    #         "name" => "...",
    #         "description" => "",
    #         "show" => true,
    #         "endpoints" => [ { "method" =>, "path" =>, ... }, ... ]
    #       }
    #     }
    #   }
    class Builder
      DEFAULT_GENERAL = {
        "title"           => "API Documentation",
        "base_url"        => "https://api.example.com",
        "primary_color"   => "#CC0000",
        "secondary_color" => "#2E2E2E",
        "accent_color"    => "#D30001",
        "font_family"     => "system-ui, -apple-system, sans-serif",
        "show_curl"       => true,
        "show_examples"   => true
      }.freeze

      ACTION_VERB_PHRASE = {
        "index"   => "List",
        "show"    => "Show",
        "new"     => "New",
        "create"  => "Create",
        "edit"    => "Edit",
        "update"  => "Update",
        "destroy" => "Delete"
      }.freeze

      def initialize(routes:, general: nil, body_inferrer: nil, verbose: false)
        @routes        = routes
        @general       = general || DEFAULT_GENERAL.dup
        @body_inferrer = body_inferrer
        @verbose       = verbose
      end

      def call
        {
          "general_configurations" => @general,
          "sections"               => build_sections
        }
      end

      def to_yaml
        YAML.dump(call)
      end

      private

      def build_sections
        @routes.group_by { |r| r[:controller] }.each_with_object({}) do |(controller, routes), acc|
          acc[controller] = {
            "name"        => section_name(controller),
            "description" => "",
            "show"        => true,
            "endpoints"   => routes.map { |r| build_endpoint(r) }
          }
        end
      end

      def section_name(controller)
        controller.split("/").last.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
      end

      def build_endpoint(route)
        endpoint = {
          "method"      => route[:verb],
          "path"        => route[:path],
          "name"        => endpoint_name(route),
          "description" => "",
          "show"        => true
        }

        endpoint.merge!(verbose_endpoint_meta) if @verbose

        params = path_params(route)
        endpoint["params"] = params unless params.empty?
        endpoint["params"] = [] if @verbose && params.empty?   # discoverability

        body = @body_inferrer&.call(controller: route[:controller], action: route[:action])
        endpoint["body"] = body if body && !body.empty?
        endpoint["body"] = [] if @verbose && (body.nil? || body.empty?)

        endpoint["request_example"] = "" if @verbose
        endpoint["responses"]       = response_stub

        endpoint
      end

      def response_stub
        if @verbose
          { "200" => { "description" => "", "headers" => [], "schema" => [], "example" => "" } }
        else
          { "200" => { "description" => "", "example" => "" } }
        end
      end

      # Methods (not frozen constants) so each endpoint gets fresh array
      # values — otherwise YAML.dump emits noisy anchors tying multiple
      # endpoints together.
      def verbose_endpoint_meta
        { "deprecated" => false, "auth" => "", "tags" => [], "headers" => [] }
      end

      def verbose_field_defaults
        {
          "format"      => "",
          "enum"        => [],
          "default"     => nil,
          "min"         => nil,
          "max"         => nil,
          "min_length"  => nil,
          "max_length"  => nil,
          "pattern"     => "",
          "read_only"   => false,
          "write_only"  => false,
          "nullable"    => false
        }
      end

      def path_params(route)
        Array(route[:path_params]).map do |name|
          type = path_param_type(name.to_s)
          base = {
            "name"        => name.to_s,
            "type"        => type,
            "required"    => true,
            "in"          => "path",
            "description" => "",
            "example"     => RailsApiDocs::SampleValue.for(type)
          }
          @verbose ? base.merge(verbose_field_defaults) : base
        end
      end

      def path_param_type(name)
        name == "id" || name.end_with?("_id") ? "integer" : "string"
      end

      def endpoint_name(route)
        phrase = ACTION_VERB_PHRASE[route[:action]] || humanize(route[:action])
        noun   = route[:action] == "index" ? pluralize_last_segment(route[:controller])
                                           : singularize_last_segment(route[:controller])
        "#{phrase} #{noun.capitalize}"
      end

      def humanize(action)
        action.to_s.tr("_", " ").capitalize
      end

      def singularize_last_segment(controller)
        controller.split("/").last.to_s.singularize
      end

      def pluralize_last_segment(controller)
        controller.split("/").last.to_s.pluralize
      end
    end
  end
end
