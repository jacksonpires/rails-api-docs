# frozen_string_literal: true

module RailsApiDocs
  module Doc
    # Pure-Ruby responder that decides what to serve at /rails/api-docs.
    # Sits between the Rails controller and the Renderer so that the
    # decision logic (file present? render fresh; file missing? show setup
    # page) can be unit-tested without booting a Rails app.
    class Responder
      def initialize(config_path:)
        @config_path = config_path
      end

      # Returns [status, html_string].
      def render
        if File.exist?(@config_path)
          html = Doc::Renderer.new(Config::Loader.load(@config_path)).call
          [200, html]
        else
          [404, missing_config_page]
        end
      end

      private

      def missing_config_page
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <title>rails-api-docs · setup needed</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 640px; margin: 80px auto; padding: 0 24px; color: #1F1F1F; line-height: 1.55; }
              h1 { color: #CC0000; font-size: 24px; margin-bottom: 16px; letter-spacing: -0.01em; }
              p { margin: 12px 0; color: #4B5563; }
              code { background: #F4F4F4; padding: 2px 6px; border-radius: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; color: #1F1F1F; }
              pre { background: #1B1B1F; color: #E5E5E5; padding: 16px 18px; border-radius: 8px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; margin: 20px 0; overflow-x: auto; }
              .hint { color: #6B7280; font-size: 13px; margin-top: 28px; }
            </style>
          </head>
          <body>
            <h1>rails-api-docs is installed — but the config file isn't there yet.</h1>
            <p>Expected to find <code>#{ERB::Util.html_escape(@config_path)}</code>.</p>
            <p>Run this in your terminal to generate it from your routes:</p>
            <pre>$ rails g rails-api-docs:init</pre>
            <p>Then edit the YAML to add descriptions / examples / body fields, and reload this page.</p>
            <p class="hint">This page is only mounted in <code>development</code>. The generated <code>public/api-docs.html</code> is what gets served everywhere else — see <code>rake rails-api-docs:build</code>.</p>
          </body>
          </html>
        HTML
      end
    end
  end
end
