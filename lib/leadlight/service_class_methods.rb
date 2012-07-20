require 'leadlight/basic_converter'

module Leadlight
  module ServiceClassMethods
    fattr(:tints) { default_tints }

    def url(new_url=:none)
      if new_url == :none
        @url ||= Addressable::URI.parse('http://example.com')
      else
        @url = Addressable::URI.parse(new_url)
      end
    end

    def session(options={})
      sessions[options]
    end

    def sessions
      @sessions ||= Hash.new{|h,k|
        h[k] = new(k)
      }
    end

    def connection_stack
      @connection_stack ||= ->(builder){}
    end

    def default_tints
      [
       EnumerableRepresentation::Tint
      ]
    end

    def request_class
      @request_class ||= Class.new(Request)
    end

    private

    def tint(name, options={}, &block)
      self.tints << Tint.new(name, options, &block)
    end

    # Declare a new type mapping. Either pass a converter ("type")
    # class, or pass a block which defines #decode and #encode
    # methods.
    def type_mapping(enctype_patterns,
                     object_patterns,
                     converter_class=make_converter_class,
                     &converter_definition)
      converter_class.module_eval(&converter_definition) if converter_definition
      on_init do
        type_map.add(enctype_patterns, object_patterns, converter_class.new(codec))
      end
    end

    def build_connection(&block)
      @connection_stack = block
    end

    def http_adapter(*http_adapter_options)
      if http_adapter_options.empty?
        @http_adapter ||= [:net_http]
      else
        @http_adapter = http_adapter_options
      end
    end

    def make_converter_class
      Class.new do
        include BasicConverter
      end
    end

  end
end
