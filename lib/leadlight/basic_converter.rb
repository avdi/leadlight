module Leadlight
  module BasicConverter
    fattr(:codec) { Codec.new }

    def initialize(codec)
      @codec = codec
    end

    def decode_with_type(content_type, entity_body, options={})
      codec.decode(content_type, entity_body, options)
    end

    def encode_with_type(content_type, object, options={})
      body = codec.encode(content_type, object, options)
      Entity.new(content_type, body)
    end
  end
end
