# frozen_string_literal: true

require "rails/generators"
require "rails-api-docs"

module RailsApiDocs
  module Generators
    # The full implementation lives here. `UpdateGenerator` is a thin alias
    # subclass that just overrides the namespace — see update_generator.rb.
    # Both invocations run identical code; the distinction is semantic:
    #
    #   rails g rails-api-docs:init    # scaffold the YAML the first time
    #   rails g rails-api-docs:update  # re-run to absorb new routes
    #
    # The generator self-detects whether the YAML already exists and either
    # creates it fresh (init flow) or appends only new routes (update flow).
    # Existing entries are never modified — safe to re-run any time.
    class InitGenerator < ::Rails::Generators::Base
      # Force the hyphenated namespace so the CLI is `rails g rails-api-docs:init`,
      # matching the gem name (the module-derived default would be `rails_api_docs:init`).
      namespace "rails-api-docs:init"

      desc <<~DESC
        Initialize config/rails-api-docs.yml from your Rails app's routes.

        Scaffolds the full config with every discovered route. To absorb
        new routes after editing your routes file later, run
        `rails g rails-api-docs:update` — it appends new routes without
        touching existing entries.
      DESC

      # `nil` default lets us distinguish "flag not passed" (fall back to
      # global config) from explicit `--no-api-only` (override config).
      class_option :api_only, type: :boolean, default: nil,
                              desc: "Only include routes whose controller is JSON-returning " \
                                    "(ActionController::API descendant, or action has `render json:`)"

      class_option :only_controllers, type: :array, default: nil,
                                      desc: "Whitelist controllers (others are dropped). " \
                                            "Accepts space-, comma-, or bracket-separated names. " \
                                            "Bare names match across namespaces (e.g. 'users' matches " \
                                            "both `users` and `api/v1/users`); paths with '/' are exact. " \
                                            "Examples:\n" \
                                            "  --only-controllers users posts\n" \
                                            "  --only-controllers=users,posts,comments\n" \
                                            "  --only-controllers=[users,posts,comments]\n" \
                                            "  --only-controllers api/v1/users  # namespaced exact"

      class_option :verbose_yaml, type: :boolean, default: nil,
                                  desc: "Emit every possible YAML key per endpoint and field " \
                                        "(format, enum, default, min/max, pattern, read/write_only, " \
                                        "nullable, response headers/schema, etc.) with defaults. " \
                                        "Default (without flag) emits the commonly-edited subset only."

      def create_or_update_config_file
        routes    = Inspectors::RouteInspector.new(
                      route_set: RailsApiDocs.configuration.route_source,
                      config:    scoped_config
                    ).call
        routes    = filter_json_only(routes) if api_only?

        inferrer  = Inspectors::BodyInferrer.new(root: destination_root, verbose: verbose_yaml?)
        generated = Config::Builder.new(routes: routes, body_inferrer: inferrer, verbose: verbose_yaml?).call

        if File.exist?(absolute_path)
          append_into_existing(generated)
        else
          create_fresh(generated)
        end
      end

      private

      def api_only?
        options[:api_only].nil? ? RailsApiDocs.configuration.api_only : options[:api_only]
      end

      def verbose_yaml?
        options[:verbose_yaml].nil? ? RailsApiDocs.configuration.verbose_yaml : options[:verbose_yaml]
      end

      def filter_json_only(routes)
        detector = Inspectors::JsonRouteDetector.new(root: destination_root)
        kept     = routes.select { |r| detector.call(controller: r[:controller], action: r[:action]) }
        skipped  = routes.size - kept.size
        say_status :filtered, "--api-only kept #{kept.size}/#{routes.size} routes (#{skipped} non-JSON skipped)", :cyan if skipped.positive?
        kept
      end

      # Returns a per-run configuration: a dup of the global config with
      # CLI-supplied options overlaid. Inspectors get this explicit config
      # so we don't mutate global state.
      def scoped_config
        cfg          = RailsApiDocs.configuration.dup
        only_ctrls   = parse_only_controllers
        cfg.only_controllers = only_ctrls if only_ctrls
        cfg
      end

      # Accepts all four CLI forms:
      #   --only-controllers users posts            (space — Thor native array)
      #   --only-controllers=users,posts            (comma)
      #   --only-controllers=[users,posts,comments] (bracketed)
      #   --only-controllers=[ users , posts ]      (whitespace inside)
      # Returns nil if flag wasn't passed, [] if passed but empty after parsing.
      def parse_only_controllers
        raw = options[:only_controllers]
        return nil unless raw

        raw.flat_map { |item| item.gsub(/[\[\]]/, "").split(",") }
           .map(&:strip)
           .reject(&:empty?)
      end

      def relative_path
        RailsApiDocs.configuration.config_path
      end

      def absolute_path
        File.join(destination_root, relative_path)
      end

      def create_fresh(generated)
        content = file_header + YAML.dump(generated)
        create_file relative_path, content
      end

      def append_into_existing(generated)
        existing = Config::Loader.load(absolute_path)
        appender = Config::Appender.new(existing: existing, generated: generated)

        unless appender.changes?
          say_status :unchanged, relative_path, :yellow
          return
        end

        header  = Config::Loader.header(absolute_path)
        merged  = appender.call
        content = (header.empty? ? file_header : header) + YAML.dump(merged)

        File.write(absolute_path, content)

        d              = appender.diff
        new_sections   = d[:new_sections].size
        new_endpoints  = d[:new_endpoints_by_section].values.sum(&:size)
        say_status :updated, "#{relative_path} (+#{new_sections} section(s), +#{new_endpoints} endpoint(s))", :green
      end

      def file_header
        <<~YAML
          # config/rails-api-docs.yml
          # Auto-generated by rails-api-docs.
          #
          # You can safely edit this file:
          #   - Add descriptions, examples, body fields and params.
          #   - Set `show: false` to hide a route or section from the docs.
          #   - Tweak `general_configurations` (colors, title, base_url, etc.).
          #
          # Re-run `rails g rails-api-docs:update` whenever your routes change —
          # it only APPENDS new routes; existing entries are never modified.
          # Delete a section/endpoint from this file to have it regenerated.

        YAML
      end
    end
  end
end
