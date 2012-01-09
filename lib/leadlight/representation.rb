require 'addressable/uri'
require 'leadlight/link'

module Leadlight
  module Representation
    attr_accessor :__service__
    attr_accessor :__location__
    attr_accessor :__response__
    attr_accessor :__type__

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


    private

    def __apply_tint__
    end
  end
end
