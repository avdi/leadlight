require 'fattr'
require 'forwardable'

module Leadlight
  class ConnectionBuilder
    extend Forwardable

    fattr(:url)
    fattr(:service)
    fattr(:common_stack)
    fattr(:adapter)

    def_delegators :service, :connection_stack, :logger

    def initialize
      yield self if block_given?
    end

    def call
      Faraday.new(url: url.to_s) do |connection|
        connection.use Leadlight::ServiceMiddleware, service: service
        connection.use Faraday::Response::Logger, logger
        service.instance_exec(connection, &connection_stack)
        service.instance_exec(connection, &common_stack)
        connection.adapter = adapter
      end
    end
  end
end
