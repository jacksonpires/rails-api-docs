# frozen_string_literal: true

module RailsApiDocs
  module Inspectors
    # Composes ControllerInspector + SchemaInspector to produce a typed body
    # field list for write actions (create / update).
    #
    # Returned shape per call:
    #
    #   [
    #     { "name" => "email", "type" => "string", "required" => true },
    #     { "name" => "age",   "type" => "integer", "required" => false }
    #   ]
    #
    # Returns `nil` (not an empty array) when there's nothing useful to add —
    # the Builder uses that to decide whether to emit a `body:` key at all.
    class BodyInferrer
      WRITE_ACTIONS = %w[create update].freeze

      def initialize(root: nil, controller_inspector: nil, schema_inspector: nil, verbose: false)
        @root                       = root
        @controller_inspector_class = controller_inspector || ControllerInspector
        @schema_inspector_class     = schema_inspector     || SchemaInspector
        @verbose                    = verbose
        @cache                      = {}
      end

      def call(controller:, action:)
        return nil unless WRITE_ACTIONS.include?(action.to_s)

        permitted = controller_permits(controller)
        return nil if permitted.empty?

        types = column_types(controller)

        permitted.map { |name| build_field(name, types[name]) }
      end

      private

      def build_field(name, col)
        type     = col ? col[:type].to_s : "string"
        required = col ? required?(col) : false
        base = {
          "name"        => name,
          "type"        => type,
          "required"    => required,
          "description" => "",
          "example"     => RailsApiDocs::SampleValue.for(type)
        }
        @verbose ? base.merge(verbose_field_defaults) : base
      end

      # Returned as a fresh hash (and fresh array/value instances inside) so
      # multiple fields don't share references — otherwise `YAML.dump` emits
      # noisy anchors (`enum: &1 []` / `enum: *1`) tying them together.
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

      def required?(col)
        !col[:null] && col[:default].nil?
      end

      def controller_permits(controller)
        @cache[[:permits, controller]] ||=
          @controller_inspector_class.new(controller: controller, root: @root).call
      end

      def column_types(controller)
        @cache[[:schema, controller]] ||=
          @schema_inspector_class.new(controller: controller).call
      end
    end
  end
end
