# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"
require "rails/generators"
require "rails/generators/test_case"

require "rails-api-docs"
require "generators/rails-api-docs/init/init_generator"
require "generators/rails-api-docs/update/update_generator"

require "minitest/autorun"
