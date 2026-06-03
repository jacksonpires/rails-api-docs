# frozen_string_literal: true

namespace :"rails-api-docs" do
  desc "Generate the API docs HTML at public/api-docs.html from config/rails-api-docs.yml.\n" \
       "Override paths with CONFIG= and OUTPUT= env vars if needed."
  task build: :environment do
    config_relative = ENV["CONFIG"] || RailsApiDocs.configuration.config_path
    output_relative = ENV["OUTPUT"] || RailsApiDocs.configuration.output_path

    config_path = Rails.root.join(config_relative).to_s
    output_path = Rails.root.join(output_relative).to_s

    begin
      written = RailsApiDocs::Doc::FileBuilder.new(
        config_path: config_path,
        output_path: output_path
      ).call

      puts "[rails-api-docs] wrote #{written} (#{File.size(written)} bytes)"
    rescue RailsApiDocs::Doc::FileBuilder::MissingConfigError => e
      warn "[rails-api-docs] #{e.message}"
      exit 1
    end
  end
end
