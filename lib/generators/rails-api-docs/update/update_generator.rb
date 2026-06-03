# frozen_string_literal: true

require_relative "../init/init_generator"

module RailsApiDocs
  module Generators
    # Alias for InitGenerator with a different namespace. Both commands run
    # the same code; this one reads more naturally for re-runs:
    #
    #   rails g rails-api-docs:update              # equivalent to :init
    #   rails g rails-api-docs:update --api-only   # all flags supported
    #
    # The generator's behavior is self-detecting (file exists → append-only
    # merge; file missing → fresh scaffold), so the practical distinction is
    # purely the name printed in `rails g --help`.
    class UpdateGenerator < InitGenerator
      namespace "rails-api-docs:update"

      desc <<~DESC
        Update config/rails-api-docs.yml with new routes from your Rails app.

        Append-only: only routes not yet in the YAML are added — existing
        entries (and your edits) are never modified. Accepts the same flags
        as `rails g rails-api-docs:init`.
      DESC
    end
  end
end
