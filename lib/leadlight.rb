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
require 'leadlight/service_class_methods'
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


end
