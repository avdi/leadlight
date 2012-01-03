require 'delegate'
require 'mime/types'

module Leadlight
  class TintHelper < SimpleDelegator
    def initialize(representation, tint)
      @tint = tint
      super(representation)
    end

    def exec_tint(&block)
      catch(:halt_tint) do
        instance_eval(&block)
      end
      self
    end

    def match(&block)
      matched = instance_eval(&block)
      throw :halt_tint unless matched
    end

    def match_path(pattern)
      match{ pattern === __location__.path }
    end

    def match_content_type(pattern)
      content_type = __response__.env[:response_headers]['Content-Type'].to_s
      throw :halt_tint if content_type.empty?
      mimetype = MIME::Type.new(content_type)
      match{
        # Gotta get rid of the type params
        pattern === "#{mimetype.media_type}/#{mimetype.sub_type}"
      }
    end

    def match_class(klass)
      match{ klass === __getobj__}
    end

    def add_header(name, value)
      __response__.env[:response_headers][name] = value
    end

    def extend(mod=nil, &block)
      if mod && block
        raise ArgumentError, 'Module or block, not both'
      end
      if mod
        __getobj__.extend(mod)
      else
        __getobj__.extend(Module.new(&block))
      end
    end
  end
end
