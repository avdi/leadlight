require 'monitor'
require 'fattr'
require 'hookr'

module Leadlight
  class Request
    include HookR::Hooks
    include MonitorMixin

    fattr(:http_method)
    fattr(:url)
    fattr(:connection)
    fattr(:body)

    define_hook :on_prepare_request, :request
    define_hook :on_complete,        :response

    def initialize(connection, url, method, body=nil)
      self.connection  = connection
      self.url         = url
      self.http_method = method
      self.body        = body
      @completed       = new_cond
      @state           = :initialized
      @env             = nil
      super
    end

    def submit
      connection.run_request(http_method, url, body, {}) do |request|
        execute_hook(:on_prepare_request, request)
      end.on_complete do |env|
        execute_hook :on_complete, Faraday::Response.new(env)
        @env = env
        synchronize do
          @state = :completed
          @completed.broadcast
        end
      end
    end

    def wait
      synchronize do
        @completed.wait_until{:completed == @state}
      end
      yield(@env.fetch(:leadlight_representation)) if block_given?
      self
    end

    def submit_and_wait(&block)
      submit
      wait(&block)
    end
    alias_method :then, :submit_and_wait
  end
end
