require 'faraday'
require 'fattr'
require 'logger'
require 'leadlight/errors'
require 'leadlight/link'
require 'leadlight/hyperlinkable'
require 'leadlight/service_middleware'
require 'leadlight/representation'
require 'leadlight/tint'
require 'leadlight/type'
require 'leadlight/service'
require 'leadlight/enumerable_representation'


module Leadlight

  VERSION = '0.0.2'

  def self.build_service(target=Class.new, &block)
    target.tap do
      target.module_eval do
        extend ServiceClassMethods
        include Service
        extend SingleForwardable
        
        request_events = request_class.hooks.map(&:name)
        def_delegators :request_class, *request_events
      end
      target.module_eval(&block)
    end
  end

  def self.build_connection_common(&common_connection_stack)
    @common_connection_stack = common_connection_stack
  end

  def self.common_connection_stack
    @common_connection_stack ||= ->(builder) {
      builder.adapter :net_http
    }
  end

  module ServiceClassMethods
    fattr(:tints) { default_tints }
    fattr(:types) { []            }

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

    def type(name, &block)
      self.types << Type.new(name, self, &block)
    end

    def type_for_name(name)
      raise_on_missing = -> do
        raise KeyError, "Type not found: #{name}"
      end
      types.detect(raise_on_missing){|type| type.name.to_s == name.to_s}
    end

    def build_connection(&block)
      @connection_stack = block
    end

  end

end
