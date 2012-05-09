require 'addressable/uri'
require 'leadlight/link'
require 'leadlight/errors'

module Leadlight
  module Representation
    attr_accessor :__service__
    attr_accessor :__location__
    attr_accessor :__response__

    def initialize_representation(service, location, response)
      self.__service__ = service
      self.__location__ = location
      self.__response__ = response
      self
    end

    def apply_all_tints
      __service__.tints.inject(self, &:extend)
      __apply_tint__
      self
    end

    def exception
      return super if defined?(super)
      case __response__.status.to_i
      when 404 then ResourceNotFound
      when (400..499) then ClientError
      when (500..599) then ServerError
      end.new(__response__, exception_message)
    end

    def exception_message
      http_status_message
    end

    def http_status_message
      __response__.env.fetch(:response_headers).fetch('status'){
        status.to_s
      }
    end

    private

    def __apply_tint__
    end
  end
end
