require 'addressable/uri'

module Leadlight
  class NullLink
    include Addressable
    attr_reader :href

    def initialize(href)
      @href = href
    end

    def ==(other)
      other.is_a?(self.class) &&
        href == other.href
    end

    def params
      URI.parse(href).query_values || {}
    end
  end
end
