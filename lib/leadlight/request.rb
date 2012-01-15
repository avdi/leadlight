require 'monitor'
require 'fattr'
require 'forwardable'
require 'hookr'
require 'leadlight/errors'
require 'leadlight/blank'
require 'leadlight/hyperlinkable'
require 'leadlight/representation'
require 'leadlight/deadline'

module Leadlight
  class Request
    include HookR::Hooks
    include MonitorMixin
    extend Forwardable

    fattr(:http_method)
    fattr(:url)
    fattr(:connection)
    fattr(:body)
    fattr(:params)
    fattr(:service)

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
      connection.run_request(http_method, url, body, {}) do |request|
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

    def raise_on_error
      on_or_after_complete do |response|
        unless response.success?
          raise response.env.fetch(:leadlight_representation)
        end
      end
      self
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
      representation = if (env[:body] || '').size > 0
        ::MultiJson.decode(env[:body])
      else
        Blank.new
      end
      representation.
        extend(Representation).
        initialize_representation(env[:leadlight_service], env[:url], env[:response]).
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
