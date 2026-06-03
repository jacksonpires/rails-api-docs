# frozen_string_literal: true

module RailsApiDocs
  module Inspectors
    # Looks up the ActiveRecord model corresponding to a controller and
    # returns its columns metadata:
    #
    #   { "name" => { type: :string, null: false, default: nil }, ... }
    #
    # If the model can't be resolved or ActiveRecord isn't loaded, returns
    # an empty hash — schema inference is always best-effort.
    class SchemaInspector
      DEFAULT_RESOLVER = lambda do |controller|
        last       = controller.split("/").last.to_s
        model_name = last.singularize.camelize
        Object.const_get(model_name) if Object.const_defined?(model_name)
      end

      def initialize(controller:, model_resolver: nil)
        @controller     = controller
        @model_resolver = model_resolver || DEFAULT_RESOLVER
      end

      def call
        model = @model_resolver.call(@controller)
        return {} unless model && model.respond_to?(:columns_hash)

        model.columns_hash.each_with_object({}) do |(name, col), acc|
          acc[name.to_s] = { type: col.type, null: col.null, default: col.default }
        end
      rescue StandardError
        {}
      end
    end
  end
end
