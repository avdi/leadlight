module Leadlight
  class Codec
    def decode(content_type, entity_body, options={})
      case content_type.to_s.strip.split.first
      when %r{^text/plain}
        entity_body
      when %r{^application/json}, %r{\+json$}
        ::MultiJson.decode(entity_body, options)
      else
        raise ArgumentError, "Unrecognized content type #{content_type.inspect}"
      end
    end
  end
end
