# frozen_string_literal: true

module RailsApiDocs
  class Configuration
    attr_accessor :config_path, :output_path, :mount_path, :mount_in_development,
                  :ignored_path_prefixes, :ignored_controllers, :ignored_actions,
                  :only_controllers, :api_only, :verbose_yaml
    attr_writer :route_source

    def initialize
      @config_path           = "config/rails-api-docs.yml"
      @output_path           = "public/api-docs.html"
      @mount_path            = "/rails/api-docs"
      @mount_in_development  = true
      @route_source          = nil

      # User-extensible filters applied by RouteInspector. They stack on top
      # of the built-in INTERNAL_PREFIXES list — they don't replace it.
      #
      # ignored_* are blacklists. only_controllers is a whitelist. Strings
      # without "/" match by boundary-aware suffix (so "users" matches
      # `users` and `api/v1/users` but not `super_users`). Strings with "/"
      # match exactly. Regexps match via `Regexp#match?`.
      # Blacklist wins when a controller is in both lists.
      @ignored_path_prefixes = []
      @ignored_controllers   = []
      @ignored_actions       = []
      @only_controllers      = []

      # When true, scaffold only includes routes whose controller is JSON-returning
      # (inherits from ActionController::API, or has `render json:` in the action body).
      # Can be set per-run via `rails g rails-api-docs:init --api-only` (or `:update`).
      @api_only              = false

      # When true, scaffold emits EVERY possible YAML key per endpoint and field
      # (format, enum, default, min/max, pattern, read/write_only, nullable,
      # response headers/schema, etc.) with defaults — full discoverability at
      # the cost of much longer files. Default (false) emits only the commonly-
      # edited keys: description, example, and the existing inferred fields.
      # Per-run via `--verbose-yaml`.
      @verbose_yaml          = false
    end

    # Default lazy lookup — resolved at call time so Rails.application is set
    # by the time the generator runs. Tests can inject a custom RouteSet.
    def route_source
      @route_source || Rails.application.routes
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
