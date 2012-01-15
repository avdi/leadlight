require 'forwardable'

module Leadlight
  class Error < StandardError; end
  class CredentialsRequiredError < Error; end
  class HttpError < Error
    extend Forwardable

    attr_reader :response

    def_delegator :response, :status

    def initialize(response, message=response.status.to_s)
      @response = response
      super(message)
    end
  end
  class ClientError < HttpError; end
  class ResourceNotFound < ClientError; end
  class ServerError < HttpError; end
end
