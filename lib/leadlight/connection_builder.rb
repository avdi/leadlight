require 'fattr'
require 'forwardable'

module Leadlight
  class ConnectionBuilder
    extend Forwardable

    fattr(:url)
    fattr(:service)

    def_delegators :service, :connection_stack, :logger

    def initialize
      yield self if block_given?
    end

    def call
      Faraday.new(url: url.to_s) do |connection|
        builder = connection.builder
        builder.use Leadlight::ServiceMiddleware, service: service
        builder.use Faraday::Response::Logger, logger
        service.instance_exec(builder, &connection_stack)
        unless builder.handlers.any?{|h| h.is_a?(Faraday::Adapter)}
          service.instance_exec(builder, &Leadlight.common_connection_stack)
        end
      end
    end
  end
end
