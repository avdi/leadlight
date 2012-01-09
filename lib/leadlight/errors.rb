module Leadlight
  class Error < StandardError; end
  class CredentialsRequiredError < Error; end
  class HttpError < Error
    attr_reader :response
    def initialize(response)
      @response = response
      super("HTTP Error #{response.status}")
    end
  end
  class ClientError < HttpError; end
  class ResourceNotFound < ClientError; end
  class ServerError < HttpError; end
end
