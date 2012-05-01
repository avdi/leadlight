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
      Faraday.new(url: url.to_s) do |builder|
        builder.use Leadlight::ServiceMiddleware, service: service
        service.instance_exec(builder, &connection_stack)
        builder.use Faraday::Response::Logger, logger
        service.instance_exec(builder, &Leadlight.common_connection_stack)
      end
    end
  end
end
