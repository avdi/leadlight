require 'fattr'

module Leadlight
  module Service
    attr_reader :options
    fattr(:logger) { options.fetch(:logger) { ::Logger.new($stderr) } }
    fattr(:tints)  { self.class.tints }

    def initialize(options={})
      @options = options
    end

    def root
      get('/') do |r|
        return r
      end
    end

    def url
      self.class.url
    end

    def connection
      @connection ||= Faraday.new(url: self.url) do |builder|
        builder.use Leadlight::ServiceMiddleware, service: self
        instance_exec(builder, &connection_stack)
        builder.use Faraday::Response::Logger, logger
        instance_exec(builder, &Leadlight.common_connection_stack)
      end
    end

    def get(path)
      result = connection.get(path) do |req|
        prepare_request(req)
      end
      yield result.env[:leadlight_representation] if block_given?
      nil
    end

    private

    def prepare_request(request)
      # Override in subclasses
    end

    def connection_stack
      self.class.connection_stack
    end
  end
end
