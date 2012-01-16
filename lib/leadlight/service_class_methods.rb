module Leadlight
  module ServiceClassMethods
    fattr(:tints) { default_tints }

    def url(new_url=:none)
      if new_url == :none
        @url ||= Addressable::URI.parse('http://example.com')
      else
        @url = Addressable::URI.parse(new_url)
      end
    end

    def session(options={})
      sessions[options]
    end

    def sessions
      @sessions ||= Hash.new{|h,k|
        h[k] = new(k)
      }
    end

    def connection_stack
      @connection_stack ||= ->(builder){}
    end

    def default_tints
      [
       EnumerableRepresentation::Tint
      ]
    end

    def request_class
      @request_class ||= Class.new(Request)
    end

    private

    def tint(name, options={}, &block)
      self.tints << Tint.new(name, options, &block)
    end

    def build_connection(&block)
      @connection_stack = block
    end

  end
end
