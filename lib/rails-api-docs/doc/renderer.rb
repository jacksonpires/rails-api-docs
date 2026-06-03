# frozen_string_literal: true

require "erb"
require "json"

module RailsApiDocs
  module Doc
    # Turns the parsed YAML config into the final self-contained HTML
    # document. Used by both the rake task (writes to public/api-docs.html)
    # and the dev controller mounted at /rails/api-docs.
    #
    # The output is a single HTML string with CSS and JS inlined — no
    # external assets, no asset pipeline required.
    class Renderer
      TEMPLATE_PATH = File.expand_path("../templates/api_docs.html.erb", __dir__)

      DEFAULT_GENERAL = {
        "title"           => "API Documentation",
        "base_url"        => "https://api.example.com",
        "primary_color"   => "#CC0000",
        "secondary_color" => "#2E2E2E",
        "accent_color"    => "#D30001",
        "font_family"     => "system-ui, -apple-system, sans-serif",
        "show_curl"       => true,
        "show_examples"   => true
      }.freeze

      def initialize(config)
        @config = config || {}
      end

      def call
        ERB.new(File.read(TEMPLATE_PATH), trim_mode: "-").result(binding)
      end

      # ===== template helpers — public so ERB binding can reach them =====

      def general
        @general ||= DEFAULT_GENERAL.merge(@config["general_configurations"] || {})
      end

      def visible_sections
        @visible_sections ||= (@config["sections"] || {}).each_with_object({}) do |(key, section), acc|
          next if section["show"] == false

          endpoints = (section["endpoints"] || []).reject { |e| e["show"] == false }
          next if endpoints.empty?

          acc[key] = section.merge("endpoints" => endpoints)
        end
      end

      def empty?
        visible_sections.empty?
      end

      def h(value)
        ERB::Util.html_escape(value.to_s)
      end

      def endpoint_id(section_key, endpoint)
        method = endpoint["method"].to_s.downcase
        path   = endpoint["path"].to_s.gsub(/[^a-z0-9]+/i, "-").gsub(/^-+|-+$/, "")
        "#{section_slug(section_key)}--#{method}--#{path}"
      end

      def section_slug(key)
        key.to_s.gsub(/[^a-z0-9]+/i, "-")
      end

      def verb_class(method)
        "verb-#{method.to_s.downcase}"
      end

      def verb_label(method)
        method.to_s.upcase == "DELETE" ? "DEL" : method.to_s.upcase
      end

      def first_endpoint_id
        visible_sections.each do |key, section|
          return endpoint_id(key, section["endpoints"].first)
        end
        nil
      end

      def curl_for(endpoint)
        CurlRenderer.new(endpoint, base_url: general["base_url"]).call
      end

      # Returns an array of { status:, description:, example:, headers:, schema: }
      # always in YAML insertion order. If the user defined `responses:` in
      # the YAML we honor it verbatim; otherwise we synthesize a single
      # "200" entry from `response_example` or the inferred body sample.
      def responses_for(endpoint)
        if endpoint["responses"].is_a?(Hash) && !endpoint["responses"].empty?
          endpoint["responses"].map do |status, resp|
            resp ||= {}
            {
              "status"      => status.to_s,
              "description" => resp["description"].to_s,
              "example"     => resp["example"].to_s,
              "headers"     => Array(resp["headers"]),
              "schema"      => Array(resp["schema"])
            }
          end
        else
          [{
            "status"      => "200",
            "description" => "",
            "example"     => default_response_example(endpoint),
            "headers"     => [],
            "schema"      => []
          }]
        end
      end

      def body_present?(endpoint)
        endpoint["body"].is_a?(Array) && !endpoint["body"].empty?
      end

      def headers_present?(endpoint)
        endpoint["headers"].is_a?(Array) && !endpoint["headers"].empty?
      end

      def params_present?(endpoint)
        endpoint["params"].is_a?(Array) && !endpoint["params"].empty?
      end

      def responses_have_details?(endpoint)
        responses_for(endpoint).any? do |r|
          !r["headers"].empty? || !r["schema"].empty? || !r["description"].empty?
        end
      end

      # Returns the `data-endpoint-tags='[...]'` attribute (with leading
      # space) for a sidebar <li>, or an empty string when the endpoint
      # has no tags. JSON encoding is intentional — robust against tag
      # values that contain spaces or special characters.
      def sidebar_tags_attr(endpoint)
        tags = Array(endpoint["tags"])
        return "" if tags.empty?
        %( data-endpoint-tags='#{h(tags.to_json)}')
      end

      def auth_label(auth)
        case auth.to_s.downcase
        when "bearer" then "Bearer auth"
        when "basic"  then "Basic auth"
        when "none"   then "No auth"
        else               auth.to_s
        end
      end

      # Renders a single field row with all supported attributes. Used
      # uniformly by body, params, headers, and response schema — one
      # source of truth for badge rendering.
      def render_field(field)
        parts = []
        parts << %(<div class="field">)
        parts << %(<div class="field-row">)
        parts << %(<span class="field-name">#{h(field["name"])}</span>)
        parts << %(<span class="field-type">#{h(field["type"])}</span>) if field["type"]
        parts << %(<span class="field-badge format">#{h(field["format"])}</span>)         if field["format"]
        parts << %(<span class="field-badge in-path">#{h(field["in"])}</span>)             if field["in"]
        parts << %(<span class="field-badge readonly">read-only</span>)                    if field["read_only"]
        parts << %(<span class="field-badge writeonly">write-only</span>)                  if field["write_only"]
        parts << %(<span class="field-badge nullable">nullable</span>)                     if field["nullable"]
        parts << %(<span class="field-badge required">Required</span>)                     if field["required"]

        min = field["min"] || field["min_length"]
        max = field["max"] || field["max_length"]
        parts << %(<span class="field-meta">min: #{h(min)}</span>)                         if min
        parts << %(<span class="field-meta">max: #{h(max)}</span>)                         if max
        parts << %(<span class="field-meta">default: #{h(field["default"])}</span>)        unless field["default"].nil?
        parts << %(<span class="field-meta mono">pattern: #{h(field["pattern"])}</span>)   if field["pattern"]
        parts << %(</div>)

        if field["enum"].is_a?(Array) && !field["enum"].empty?
          values = field["enum"].map { |v| %(<code>#{h(v)}</code>) }.join(" · ")
          parts << %(<div class="field-enum">one of: #{values}</div>)
        end

        parts << %(<div class="field-desc">#{h(field["description"])}</div>) if field["description"] && !field["description"].to_s.empty?
        parts << %(<div class="field-example">Example: <code>#{h(field["example"])}</code></div>) unless field["example"].nil?

        parts << %(</div>)
        parts.join("\n")
      end

      # Helper: render an array of fields as joined HTML. Use from the
      # template like `<%= render_fields(endpoint["body"]) -%>`.
      def render_fields(fields)
        Array(fields).map { |f| render_field(f) }.join("\n")
      end

      def status_class(code)
        case code.to_s[0]
        when "2" then "status-2xx"
        when "3" then "status-3xx"
        when "4" then "status-4xx"
        when "5" then "status-5xx"
        else          ""
        end
      end

      private

      def default_response_example(endpoint)
        return endpoint["response_example"].to_s if endpoint["response_example"]

        if endpoint["body"]
          sample = endpoint["body"].each_with_object("id" => 1) do |field, acc|
            # User-provided example wins over the type-derived sample.
            acc[field["name"]] = field.key?("example") && !field["example"].nil? ?
                                   field["example"] : sample_value(field["type"])
          end
          JSON.pretty_generate(sample)
        else
          "{}"
        end
      end

      def sample_value(type)
        RailsApiDocs::SampleValue.for(type)
      end
    end
  end
end
