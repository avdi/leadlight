require 'monitor'
require 'fattr'
require 'hookr'
require 'leadlight/errors'

module Leadlight
  class Request
    include HookR::Hooks
    include MonitorMixin

    fattr(:http_method)
    fattr(:url)
    fattr(:connection)
    fattr(:body)
    fattr(:params)

    attr_reader :response    

    define_hook :on_prepare_request, :request
    define_hook :on_complete,        :response

    def initialize(connection, url, method, params={}, body=nil)
      self.connection  = connection
      self.url         = url
      self.http_method = method
      self.body        = body
      self.params      = params
      @completed       = new_cond
      @state           = :initialized
      @env             = nil
      @response        = nil
      super
    end

    def completed?
      :completed == @state
    end

    def submit
      connection.run_request(http_method, url, body, {}) do |request|
        execute_hook(:on_prepare_request, request)
      end.on_complete do |env|
        synchronize do
          @response = Faraday::Response.new(env)
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
        case response.status.to_i
        when 404
          raise ResourceNotFound, response
        when (400..499)
          raise ClientError, response
        when (500..599)
          raise ServerError, response
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
  end
end
