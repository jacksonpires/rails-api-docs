# frozen_string_literal: true

require_relative "rails-api-docs/version"
require_relative "rails-api-docs/configuration"
require_relative "rails-api-docs/sample_value"
require_relative "rails-api-docs/inspectors/route_inspector"
require_relative "rails-api-docs/inspectors/controller_inspector"
require_relative "rails-api-docs/inspectors/schema_inspector"
require_relative "rails-api-docs/inspectors/body_inferrer"
require_relative "rails-api-docs/inspectors/json_route_detector"
require_relative "rails-api-docs/config/builder"
require_relative "rails-api-docs/config/loader"
require_relative "rails-api-docs/config/appender"
require_relative "rails-api-docs/doc/curl_renderer"
require_relative "rails-api-docs/doc/renderer"
require_relative "rails-api-docs/doc/responder"
require_relative "rails-api-docs/doc/file_builder"
require_relative "rails-api-docs/engine" if defined?(Rails::Engine)

module RailsApiDocs
end
