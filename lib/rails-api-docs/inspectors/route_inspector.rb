# frozen_string_literal: true

module RailsApiDocs
  module Inspectors
    # Walks a Rails route set and produces a normalized array of hashes
    # describing each user-facing route:
    #
    #   { verb:, path:, controller:, action:, name:, path_params: }
    #
    # Internal Rails routes (mailers, conductor, active_storage, etc.) are
    # skipped. Routes without a resolvable controller/action are skipped.
    class RouteInspector
      INTERNAL_PREFIXES = %w[
        /rails/info
        /rails/conductor
        /rails/mailers
        /rails/active_storage
        /rails/action_mailbox
        /action_cable
        /assets
      ].freeze

      def initialize(route_set: nil, config: nil)
        @route_set = route_set || (defined?(Rails) && Rails.application&.routes)
        @config    = config    || (defined?(RailsApiDocs) ? RailsApiDocs.configuration : nil)
        raise ArgumentError, "no route set available" unless @route_set
      end

      def call
        @route_set.routes.flat_map { |route| extract(route) }.compact
      end

      private

      def extract(route)
        controller = route.defaults[:controller]
        action     = route.defaults[:action]
        return [] unless controller && action
        return [] if ignored_controller?(controller.to_s)
        return [] if only_controllers_active? && !only_controllers_match?(controller.to_s)
        return [] if ignored_action?(action.to_s)

        path = normalize_path(route.path.spec.to_s)
        return [] if internal?(path) || user_ignored?(path)

        verbs = verbs_for(route)
        return [] if verbs.empty?

        verbs.map do |verb|
          {
            verb: verb,
            path: path,
            controller: controller.to_s,
            action: action.to_s,
            name: route.name,
            path_params: extract_path_params(path)
          }
        end
      end

      def ignored_controller?(controller)
        Array(@config&.ignored_controllers).any? { |pattern| controller_matches?(pattern, controller) }
      end

      def only_controllers_active?
        Array(@config&.only_controllers).any?
      end

      def only_controllers_match?(controller)
        Array(@config&.only_controllers).any? { |pattern| controller_matches?(pattern, controller) }
      end

      # Shared rule for matching a controller path against a user-supplied
      # pattern. Used by both the blacklist (ignored_controllers) and the
      # whitelist (only_controllers) so the two are symmetric.
      #
      # Rules:
      #   - Regexp pattern → standard regex match.
      #   - String containing "/" → exact path match. So "api/v1/users"
      #     matches only that exact controller, not the bare "users".
      #   - String without "/" → boundary-aware suffix match. So "users"
      #     matches both `users` and `api/v1/users`, but NOT `super_users`
      #     (the boundary requires a "/" before the pattern, or equality).
      def controller_matches?(pattern, controller)
        return pattern.match?(controller) if pattern.is_a?(Regexp)

        s = pattern.to_s
        if s.include?("/")
          controller == s
        else
          controller == s || controller.end_with?("/#{s}")
        end
      end

      def ignored_action?(action)
        Array(@config&.ignored_actions).include?(action)
      end

      def user_ignored?(path)
        Array(@config&.ignored_path_prefixes).any? { |prefix| path.start_with?(prefix) }
      end

      def normalize_path(raw)
        raw.sub(/\(\.:format\)\z/, "").sub(/\/\z/, "").then { |p| p.empty? ? "/" : p }
      end

      def internal?(path)
        INTERNAL_PREFIXES.any? { |prefix| path.start_with?(prefix) }
      end

      # `route.verb` is a String in modern Rails ("GET", "POST", ...).
      # When a route accepts multiple verbs (via `match via: [:get, :post]`)
      # it can return a regex-source string like "GET|POST" — we split it.
      def verbs_for(route)
        raw = route.verb.to_s
        return [] if raw.empty?

        raw.split("|").map { |v| v.upcase.strip }.reject(&:empty?)
      end

      def extract_path_params(path)
        path.scan(/:(\w+)/).flatten
      end
    end
  end
end
