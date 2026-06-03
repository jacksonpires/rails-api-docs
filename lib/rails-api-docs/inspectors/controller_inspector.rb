# frozen_string_literal: true

require "prism"

module RailsApiDocs
  module Inspectors
    # Walks a controller file via Prism and returns the list of attribute
    # names declared in any `params.require(:X).permit(...)` (or
    # `params.permit(...)`) call inside the file.
    #
    # This is a deliberately coarse pass — we don't try to map a permit
    # call back to a specific action. In typical Rails controllers strong
    # params live in a single shared `*_params` method used by both create
    # and update, so the flat list of permitted attributes is enough for
    # documentation purposes.
    #
    # Limitations (Phase 5):
    #   - Nested permits (`permit(items: [:name])`) — only top-level scalar
    #     keys are extracted; the nested array is ignored.
    #   - Method-call args inside permit (e.g. `permit(*PERMITTED)`) — not
    #     resolved; only literal symbols/strings are picked up.
    class ControllerInspector
      def initialize(controller:, root: nil)
        @controller = controller
        @root       = root || (defined?(Rails) && Rails.root ? Rails.root.to_s : ".")
      end

      def call
        return [] unless File.exist?(file_path)

        result  = Prism.parse_file(file_path)
        visitor = PermitVisitor.new
        visitor.visit(result.value)

        visitor.permitted.uniq.map(&:to_s)
      end

      def file_path
        File.join(@root, "app/controllers", "#{@controller}_controller.rb")
      end

      class PermitVisitor < ::Prism::Visitor
        attr_reader :permitted

        def initialize
          @permitted = []
          super
        end

        def visit_call_node(node)
          collect_permitted(node) if node.name == :permit
          super
        end

        private

        def collect_permitted(node)
          args = node.arguments&.arguments || []
          args.each do |arg|
            case arg
            when ::Prism::SymbolNode
              @permitted << arg.value
            when ::Prism::StringNode
              @permitted << arg.unescaped
            when ::Prism::KeywordHashNode, ::Prism::HashNode
              # Nested permits — pick up the top-level keys only.
              arg.elements.each do |element|
                next unless element.respond_to?(:key)
                key = element.key
                @permitted << key.value if key.is_a?(::Prism::SymbolNode)
              end
            end
          end
        end
      end
    end
  end
end
