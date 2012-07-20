require 'fattr'
require 'forwardable'
require 'leadlight/request'
require 'leadlight/connection_builder'

module Leadlight
  module Service
    extend Forwardable

    attr_reader :service_options
    fattr(:logger)  { service_options.fetch(:logger) { ::Logger.new($stderr) } }
    fattr(:tints)   { self.class.tints }
    fattr(:codec) { service_options.fetch(:codec) { Codec.new } }
    fattr(:type_map) { TypeMap.new }

    def_delegators :codec, :encode, :decode
    def_delegators 'self.class', :types, :type_for_name, :request_class, :http_adapter
    def_delegators :Leadlight, :common_connection_stack

    def initialize(service_options={})
      @service_options = service_options
      execute_hook(:on_init, self)
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
      @connection ||= ConnectionBuilder.new do |cxn|
        cxn.url          url
        cxn.service      self
        cxn.common_stack common_connection_stack
        cxn.adapter      http_adapter
      end.call
    end

    [:options, :head, :get, :post, :put, :delete, :patch].each do |name|
      define_method(name) do |url, *args, &block|
        perform_request(url, name, *args, &block)
      end
    end

    # Convenience method for a quick GET which submits, waits, raises
    # on error, and yields the representation.
    def get_representation!(*args, &block)
      get(*args).raise_on_error.submit_and_wait(&block)
    end

    private

    def perform_request(url, http_method, body_or_options=nil, options=nil, &representation_handler)
      options ||= body_or_options.is_a?(Hash) ? body_or_options : {}
      body    ||= body_or_options.is_a?(Hash) ? nil : body_or_options
      req = request_class.new(self, connection, url, http_method, body, options)
      if representation_handler
        req.submit_and_wait(&representation_handler)
      end
      req
    end

    def connection_stack
      self.class.connection_stack
    end
  end
end
