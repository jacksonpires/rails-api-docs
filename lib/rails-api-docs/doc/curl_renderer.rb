# frozen_string_literal: true

require "json"

module RailsApiDocs
  module Doc
    # Renders a copy-pasteable multi-line curl command for an endpoint.
    #
    # Body precedence:
    #   1. endpoint["request_example"] (verbatim — user has full control)
    #   2. JSON.pretty_generate of inferred sample from endpoint["body"]
    #   3. no --data (no body at all)
    #
    # Path param substitution prefers param["example"] when present,
    # otherwise falls back to a type-based sample (always "1" for integers,
    # "example" for everything else).
    class CurlRenderer
      def initialize(endpoint, base_url:)
        @endpoint = endpoint
        @base_url = base_url.to_s
      end

      def call
        lines = ["curl --request #{method} \\", "  --url #{url}"]

        all_headers = curl_headers
        all_headers.each do |name, value|
          lines[-1] += " \\"
          lines << "  --header '#{shell_escape("#{name}: #{value}")}'"
        end

        if body_present?
          lines[-1] += " \\"
          lines << "  --header 'Content-Type: application/json' \\"
          lines << "  --data '#{shell_escape(body_json)}'"
        end
        lines.join("\n")
      end

      private

      # Returns [[name, value], ...] of headers to emit before --data.
      # Order: user-declared headers (in YAML insertion order) first,
      # then an Authorization placeholder if `auth:` is set and the user
      # didn't already declare one.
      def curl_headers
        user_headers = Array(@endpoint["headers"]).map do |h|
          example = h["example"]
          example = sample_value(h["type"]) if example.nil?
          [h["name"].to_s, example.to_s]
        end

        if @endpoint["auth"] && !@endpoint["auth"].to_s.empty? &&
           !user_headers.any? { |n, _| n.casecmp?("Authorization") }
          placeholder = auth_placeholder(@endpoint["auth"])
          user_headers << ["Authorization", placeholder] if placeholder
        end

        user_headers
      end

      def auth_placeholder(auth)
        case auth.to_s.downcase
        when "bearer" then "Bearer YOUR_TOKEN_HERE"
        when "basic"  then "Basic BASE64_ENCODED_CREDENTIALS"
        when "none"   then nil
        else               auth.to_s
        end
      end

      def method
        @endpoint["method"].to_s.upcase
      end

      def url
        path = @endpoint["path"].to_s.dup
        Array(@endpoint["params"]).each do |param|
          next unless param["in"] == "path"
          path.sub!(":#{param['name']}", path_param_sample(param).to_s)
        end
        "#{@base_url}#{path}"
      end

      def path_param_sample(param)
        return param["example"] unless param["example"].nil?
        sample_value(param["type"])
      end

      def body_present?
        !@endpoint["request_example"].to_s.strip.empty? ||
          (@endpoint["body"].is_a?(Array) && !@endpoint["body"].empty?)
      end

      def body_json
        if @endpoint["request_example"] && !@endpoint["request_example"].to_s.strip.empty?
          @endpoint["request_example"].to_s.strip
        else
          hash = @endpoint["body"].each_with_object({}) do |field, acc|
            # Field's own example wins; type-derived sample is the fallback.
            acc[field["name"]] = field.key?("example") && !field["example"].nil? ?
                                   field["example"] : sample_value(field["type"])
          end
          JSON.pretty_generate(hash)
        end
      end

      # `'...'` in shell cannot contain a single quote. The standard escape
      # for `'` inside is `'\''` (close, escaped quote, reopen).
      # Block form of gsub avoids the replacement-string backslash trap
      # (`\'` would be interpreted as the post-match reference).
      def shell_escape(str)
        str.gsub("'") { "'\\''" }
      end

      def sample_value(type)
        RailsApiDocs::SampleValue.for(type)
      end
    end
  end
end
