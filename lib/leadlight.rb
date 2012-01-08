require 'faraday'
require 'fattr'
require 'logger'
require 'leadlight/errors'
require 'leadlight/link'
require 'leadlight/hyperlinkable'
require 'leadlight/service_middleware'
require 'leadlight/representation'
require 'leadlight/tint'
require 'leadlight/service'
require 'leadlight/enumerable_representation'


module Leadlight

  VERSION = '0.0.1'

  def self.build_service(target, &block)
    target.module_eval do
      extend ServiceClassMethods
      include Service
    end
    target.module_eval(&block)
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

    private

    def tint(name, &block)
      self.tints << Tint.new(name, &block)
    end

    def type(mame, &block)
      self.types << Type.new(name, self, &block)
    end

    def build_connection(&block)
      @connection_stack = block
    end

  end

end