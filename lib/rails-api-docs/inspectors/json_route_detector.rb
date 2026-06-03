# frozen_string_literal: true

require "prism"
require "set"
require "active_support/core_ext/string/inflections"

module RailsApiDocs
  module Inspectors
    # Decides whether an endpoint should be considered "JSON-returning" for
    # the `--api-only` filter on the install generator.
    #
    # Decision logic for `call(controller:, action:)`:
    #   1. If the controller's inheritance chain reaches `ActionController::API`
    #      (directly, or transitively via ApplicationController / a custom
    #      base controller) → true for every action.
    #   2. Else if the action body contains a `render json: …` call (kwarg
    #      form or hash-rocket form, including inside `respond_to` blocks)
    #      → true.
    #   3. Else → false.
    #
    # `:unknown` classifications (controller file missing, unresolvable
    # parent constant) are strict — they DO NOT count as :api. Per-action
    # render-json detection still runs if the file exists but inheritance
    # is unresolvable.
    #
    # Each controller file is parsed at most once per detector instance —
    # the same Prism AST feeds both visitors, and the result hash is cached
    # so the inheritance chain ApplicationController → ActionController::API
    # is walked once even when 50 controllers inherit from it.
    #
    # Known limitations:
    #   - `render json:` inside a helper method called from the action is
    #     not detected (we don't follow method calls).
    #   - `render template: "x", formats: :json` doesn't have a `json:`
    #     key in the call, so it's missed.
    #   - Includes (`include SomeRenderingModule`) are not traversed.
    class JsonRouteDetector
      def initialize(root: nil)
        @root  = root || (defined?(Rails) && Rails.root ? Rails.root.to_s : ".")
        @cache = {}
      end

      def call(controller:, action:)
        profile = profile_for(controller)
        return true  if profile[:type] == :api
        profile[:json_actions].include?(action.to_s)
      end

      # Exposed for testing / debugging.
      def profile_for(controller)
        @cache[controller] ||= analyze(controller)
      end

      private

      def analyze(controller)
        file = controller_path(controller)
        return blank_profile unless File.exist?(file)

        ast = ::Prism.parse_file(file).value

        sc_visitor = SuperclassVisitor.new
        sc_visitor.visit(ast)

        ja_visitor = JsonActionVisitor.new
        ja_visitor.visit(ast)

        {
          type:         classify(sc_visitor.superclass),
          json_actions: ja_visitor.actions
        }
      end

      def classify(parent_name)
        return :unknown unless parent_name

        case parent_name
        when "ActionController::API"  then :api
        when "ActionController::Base" then :html
        else
          parent_controller = parent_name.underscore.sub(/_controller\z/, "")
          # Guard against pathological cycles (e.g. file that references
          # itself somehow). The cache hit on second visit makes the loop
          # short-circuit because we'd recurse into ourselves and read
          # back the same in-progress entry — but to be safe, mark visited.
          return :unknown if @cache.key?(parent_controller)

          @cache[parent_controller] = blank_profile   # placeholder to break cycles
          @cache[parent_controller] = analyze(parent_controller)
          @cache[parent_controller][:type]
        end
      end

      def blank_profile
        { type: :unknown, json_actions: [] }
      end

      def controller_path(controller)
        File.join(@root, "app/controllers", "#{controller}_controller.rb")
      end

      # ============================================================
      # Visitors
      # ============================================================

      # Captures the superclass name from the FIRST class definition in
      # the file. Handles both simple constants (`ApplicationController`)
      # and qualified ones (`ActionController::API`, `Api::V1::BaseController`).
      class SuperclassVisitor < ::Prism::Visitor
        attr_reader :superclass

        def visit_class_node(node)
          @superclass ||= constant_name(node.superclass)
          super
        end

        private

        def constant_name(node)
          case node
          when nil
            nil
          when ::Prism::ConstantReadNode
            node.name.to_s
          when ::Prism::ConstantPathNode
            parts = []
            walk = node
            while walk.is_a?(::Prism::ConstantPathNode)
              parts.unshift(walk.name.to_s)
              walk = walk.parent
            end
            parts.unshift(walk.name.to_s) if walk.is_a?(::Prism::ConstantReadNode)
            parts.join("::")
          end
        end
      end

      # Walks every method definition and records the names of methods that
      # contain a `render` call with a `json:` keyword. Nested calls inside
      # `respond_to do |format| format.json { render json: … } end` are
      # caught because `super` recurses into child nodes.
      class JsonActionVisitor < ::Prism::Visitor
        def initialize
          @actions        = Set.new
          @current_method = nil
          super
        end

        def actions
          @actions.to_a
        end

        def visit_def_node(node)
          prev = @current_method
          @current_method = node.name.to_s
          super
          @current_method = prev
        end

        def visit_call_node(node)
          if @current_method && node.name == :render && renders_json?(node)
            @actions.add(@current_method)
          end
          super
        end

        private

        def renders_json?(call_node)
          args = call_node.arguments&.arguments || []
          args.any? { |arg| has_json_key?(arg) }
        end

        def has_json_key?(node)
          case node
          when ::Prism::KeywordHashNode, ::Prism::HashNode
            node.elements.any? do |elem|
              next false unless elem.respond_to?(:key)
              key = elem.key
              key.is_a?(::Prism::SymbolNode) && key.value.to_s == "json"
            end
          else
            false
          end
        end
      end
    end
  end
end
