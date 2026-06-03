# frozen_string_literal: true

module RailsApiDocs
  # Single source of truth for type-derived placeholder values. Used by:
  #   - BodyInferrer  → seeds `example:` for inferred body fields
  #   - Builder       → seeds `example:` for inferred path params
  #   - CurlRenderer  → fills body fields in `--data` when no example is set
  #   - Renderer      → synthesizes a default response example from body schema
  #
  # The mapping is intentionally narrow — for niche types it returns nil
  # rather than guessing, which JSON-encodes to `null` and signals to the
  # user "we don't know, fill this in".
  module SampleValue
    module_function

    def for(type)
      case type.to_s
      when "string", "text"    then "example"
      when "integer", "bigint" then 1
      when "float", "decimal"  then 1.0
      when "boolean"           then true
      when "date"              then "2026-01-01"
      when "datetime", "time"  then "2026-01-01T00:00:00Z"
      else                          nil
      end
    end
  end
end
