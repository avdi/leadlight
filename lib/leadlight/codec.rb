require 'multi_json'

module Leadlight
  class Codec
    Strategy ||= Struct.new(:name, :encoder, :decoder, :patterns)

    def self.strategies
      @strategies ||= []
    end

    def self.strategy(name, encoder, decoder, patterns)
      strategies << Strategy.new(name, encoder, decoder, Array(patterns))
    end

    strategies.clear

    strategy :text,             
             ->(rep, options)         {rep.to_s},
             ->(entity_body, options) {entity_body},
             %r{^text/plain}

    strategy :json, 
             MultiJson.method(:encode),
             MultiJson.method(:decode), 
             [%r{^application/json}, %r{\+json$}]

    def decode(content_type, entity_body, options={})
      transcode(:decode, content_type, entity_body, options)
    end

    def encode(content_type, representation, options={})
      transcode(:encode, content_type, representation, options)
    end

    private

    def transcode(direction, content_type, input, options)
      fallback = unknown_type_handler(content_type)
      strategy = fetch_strategy(content_type, &fallback)
      transcoder = case direction
                   when :encode then strategy.encoder
                   when :decode then strategy.decoder
                   else raise ArgumentError, "Should never get here"
                   end
      transcoder.(input, options)
    end

    def strategies
      self.class.strategies
    end

    def fetch_strategy(content_type, &fallback)
      content_type = content_type.to_s.strip.split.first
      strategies.detect(fallback) { |strategy|
        strategy.patterns.any?{|pattern| pattern === content_type}
      }
    end

    def unknown_type_handler(content_type)
      -> do
        raise ArgumentError, "Unrecognized content type #{content_type.inspect}"
      end
    end
  end
end
