require 'fattr'
require 'forwardable'
require 'leadlight/request'

module Leadlight
  module Service
    extend Forwardable

    attr_reader :options
    fattr(:logger)  { options.fetch(:logger) { ::Logger.new($stderr) } }
    fattr(:tints)   { self.class.tints }
    fattr(:codec) { options.fetch(:codec) { Codec.new } }

    def_delegators :codec, :encode, :decode

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

    [:head, :get, :post, :put, :delete, :patch].each do |name|
      define_method(name) do |url, *args, &block|
        perform_request(url, name, *args, &block)
      end
    end

    private

    def perform_request(url, http_method, params={}, body=nil, &representation_handler)
      req = Request.new(connection, url, http_method, params, body)
      req.on_prepare_request do |faraday_request|
        prepare_request(faraday_request)
      end
      if representation_handler
        req.submit_and_wait(&representation_handler)
      end
      req
    end

    def prepare_request(request)
      # Override in subclasses
    end

    def connection_stack
      self.class.connection_stack
    end
  end
end
