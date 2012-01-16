require 'fattr'
require 'forwardable'
require 'leadlight/codec'
require 'leadlight/errors'
require 'leadlight/blank'
require 'leadlight/entity'

module Leadlight
  class TypeMap
    fattr(:codec) { Codec.new }
    attr_reader :types

    def initialize(options={})
      options.each do |key, value|
        send key, value
      end
      @types = []
      add_default_types
    end

    def add(enctype_pattern, object_pattern, type)
      types.unshift(Mapping.new(enctype_pattern, object_pattern, type))
    end

    def to_entity_body(object, options={})
      types.detect(handle_unknown_object_type(object)) {|t|
        t.match_for_object?(object) 
      }.encode(object, options)
    end

    def to_native(content_type, entity_body, options={})
      types.detect(handle_unknown_enctype(content_type)) {|t| 
        t.match_for_enctype?(content_type) 
      }.decode(content_type, entity_body, options)
    end

    private

    def add_default_types
      add [nil, //], Object, DefaultType.new(codec)
    end

    def handle_unknown_enctype(enctype)
      -> do
        raise TypeError, "No type registered for content-type #{enctype.inspect}"
      end
    end

    def handle_unknown_object_type(object)
      -> do
        raise TypeError, "No type matches object #{object.inspect}"
      end
    end

    class Mapping
      extend Forwardable

      fattr(:enctype_patterns)
      fattr(:object_patterns)
      fattr(:type)

      def_delegators :type, :encode, :decode

      def initialize(enctype_pattern, object_pattern, type)
        enctype_patterns Array(enctype_pattern)
        object_patterns Array(object_pattern)
        self.type = type
      end

      def match_for_enctype?(enctype)
        enctype_patterns.any?{|p| p === enctype}
      end

      def match_for_object?(object)
        object_patterns.any?{|p| p === object}
      end
    end

    class DefaultType
      def initialize(codec)
        @codec = codec
      end

      def encode(object, options={})
        return Entity.new(nil, nil) if object.nil?
        content_type = options.delete(:content_type){"application/json"}
        body = @codec.encode(content_type, object, options)
        Entity.new(content_type, body)
      end

      def decode(content_type, entity_body, options={})
        case entity_body.to_s.size
        when 0,1 # No valid JSON document is smaller than 2 bytes
          Blank.new
        else
          @codec.decode(content_type, entity_body, options)
        end
      end
    end
  end
end
