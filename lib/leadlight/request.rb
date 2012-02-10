require 'monitor'
require 'fattr'
require 'forwardable'
require 'hookr'
require 'leadlight/errors'
require 'leadlight/blank'
require 'leadlight/hyperlinkable'
require 'leadlight/representation'
require 'leadlight/type_map'
require 'leadlight/header_helpers'

module Leadlight
  class Request
    include HookR::Hooks
    include MonitorMixin
    extend Forwardable
    include HeaderHelpers

    fattr(:http_method)
    fattr(:url)
    fattr(:connection)
    fattr(:body)
    fattr(:params)
    fattr(:service)
    fattr(:codec)
    fattr(:type_map) { service.type_map || TypeMap.new }

    attr_reader :response    

    define_hook :on_prepare_request, :request
    define_hook :on_complete,        :response

    def_delegator :service, :service_options

    def initialize(service, connection, url, method, params={}, body=nil)
      self.connection  = connection
      self.url         = url
      self.http_method = method
      self.body        = body
      self.params      = params
      self.service     = service
      @completed       = new_cond
      @state           = :initialized
      @env             = nil
      @response        = nil
      super()
    end

    def completed?
      :completed == @state
    end

    def submit
      entity = type_map.to_entity_body(body)
      entity_body = entity.body
      content_type = entity.content_type
      connection.run_request(http_method, url, entity_body, {}) do |request|
        request.params.update(params) unless params.empty?
        request.headers['Content-Type'] = content_type if content_type
        request.options[:leadlight_request] = self        
        execute_hook(:on_prepare_request, request)
      end.on_complete do |env|
        synchronize do
          @response = env.fetch(:response)
          execute_hook :on_complete, @response
          @env = env
          @state = :completed
          @completed.broadcast
        end
      end
    end

    def wait
      synchronize do
        @completed.wait_until{completed?}
      end
      yield(@env.fetch(:leadlight_representation)) if block_given?
      self
    end

    def submit_and_wait(&block)
      submit
      wait(&block)
    end
    alias_method :then, :submit_and_wait

    def on_error
      on_or_after_complete do |response|
        unless response.success?
          yield(response.env.fetch(:leadlight_representation))
        end
      end
      self
    end

    def raise_on_error
      on_error do |representation|
        raise representation
      end
    end

    def on_or_after_complete(&block)
      synchronize do
        if completed?
          block.call(response)
        else
          on_complete(&block)
        end
      end
    end

    def represent(env)      
      content_type = env[:response_headers]['Content-Type']
      content_type = clean_content_type(content_type)
      representation = type_map.to_native(content_type, env[:body])
      location = Addressable::URI.parse(env[:response_headers].fetch('location'){ env[:url] })
      representation.
        extend(Representation).
        initialize_representation(env[:leadlight_service], location, env[:response]).
        extend(Hyperlinkable).
        apply_all_tints
    end

    private

    def representation
      raise "No representation until complete" unless completed?
      @env.fetch(:leadlight_representation)
    end
  end
end
