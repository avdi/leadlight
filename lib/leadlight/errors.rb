require 'forwardable'

module Leadlight
  class Error < StandardError; end
  class CredentialsRequiredError < Error; end
  class HttpError < Error
    extend Forwardable

    attr_reader :request

    def_delegators :response, :status, :response

    def initialize(request, message=response.status.to_s)
      @request = request
      super(amplify_message(message))
    end

    private

    def amplify_message(message)
      "#{message} (#{request.http_method.upcase} #{request.location})"
    end
  end
  class ClientError < HttpError; end
  class ResourceNotFound < ClientError; end
  class ServerError < HttpError; end
  class TypeError < Error; end
end
