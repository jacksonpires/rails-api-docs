# frozen_string_literal: true

require_relative "lib/rails-api-docs/version"

Gem::Specification.new do |spec|
  spec.name = "rails-api-docs"
  spec.version = RailsApiDocs::VERSION
  spec.authors = ["Jackson Pires"]
  spec.email = ["jackson@linkana.com"]

  spec.summary = "Generate beautiful, self-contained HTML API documentation from your Rails routes."
  spec.description = "Inspects your Rails routes, controllers and schema to produce " \
                     "config/rails-api-docs.yml, then renders a Scalar-style three-column " \
                     "HTML page at public/api-docs.html. Includes a live preview mount at " \
                     "/rails/api-docs in development."
  spec.homepage = "https://github.com/jacksonpires/rails-api-docs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"]     = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "README.md",
    "LICENSE.txt",
    "CHANGELOG.md"
  ].reject { |f| File.directory?(f) }

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.1"
  spec.add_dependency "prism", ">= 0.24"

  spec.add_development_dependency "rails", ">= 7.1"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "sqlite3", ">= 2.0"
end
