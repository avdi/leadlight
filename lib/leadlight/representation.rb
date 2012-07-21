require 'forwardable'
require 'addressable/uri'
require 'fattr'
require 'leadlight/link'
require 'leadlight/errors'

module Leadlight
  module Representation
    extend Forwardable

    attr_accessor :__service__
    attr_accessor :__location__
    attr_accessor :__response__
    attr_accessor :__request__

    #fattr(:__captures__) { {} }

    def initialize_representation(service, location, response, request)
      self.__service__  = service
      self.__location__ = location
      self.__response__ = response
      self.__request__  = request
      self
    end

    def apply_all_tints
      __service__.tints.inject(self, &:extend)
      __apply_tint__
      self
    end

    def exception(message=exception_message)
      return super if defined?(super)
      case __response__.status.to_i
      when 404 then ResourceNotFound
      when (400..499) then ClientError
      when (500..599) then ServerError
      end.new(__request__, exception_message)
    end

    def exception_message
      http_status_message
    end

    def http_status_message
      __response__.env.fetch(:response_headers).fetch('status'){
        status.to_s
      }
    end

    def __link__
      __request__.link
    end

    def __request_params__
      __request__.params
    end

    def __captures__
      @__captures__ ||= {}
    end

    private

    def __apply_tint__
    end
  end
end
