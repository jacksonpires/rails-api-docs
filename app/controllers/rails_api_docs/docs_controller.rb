# frozen_string_literal: true

module RailsApiDocs
  class DocsController < ActionController::Base
    # We render the full HTML doc ourselves (self-contained <html>),
    # so disable the host app's layout.
    layout false

    def show
      status, html = Doc::Responder.new(config_path: full_config_path).render
      render html: html.html_safe, status: status
    end

    private

    def full_config_path
      Rails.root.join(RailsApiDocs.configuration.config_path).to_s
    end
  end
end
