module Faraday
  class Adapter < Middleware
    def self.adapter?
      true
    end
  end
end
