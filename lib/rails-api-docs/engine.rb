# frozen_string_literal: true

require "rails/engine"

module RailsApiDocs
  class Engine < ::Rails::Engine
    isolate_namespace RailsApiDocs

    rake_tasks do
      load File.expand_path("tasks/rails-api-docs.rake", __dir__)
    end

    generators do
      require_relative "../generators/rails-api-docs/init/init_generator"
      require_relative "../generators/rails-api-docs/update/update_generator"
    end

    initializer "rails_api_docs.mount" do |app|
      config = RailsApiDocs.configuration
      if config.mount_in_development && Rails.env.development?
        app.routes.append do
          mount RailsApiDocs::Engine, at: config.mount_path, as: :rails_api_docs
        end
      end
    end
  end
end
