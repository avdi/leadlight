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

    def match(*matchers, &block_matcher)
      matchers << block_matcher if block_matcher
      matched = matchers.any?{|m| m === __getobj__}
      throw :halt_tint unless matched
    end

    def match_path(pattern)
      matcher = path_matcher(pattern)
      match{ matcher.call(pattern, __location__.path, __captures__) }
    end

    def match_template(path_template)
      path_url = Addressable::URI.parse(path_template)
      full_url = __location__ + path_url
      template = Addressable::Template.new(full_url.to_s)
      match {
        match_data = template.match(__location__)
        if match_data
          __captures__.merge!(match_data.mapping)
        end
      }
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

    def match_status(*patterns)
      patterns = expand_status_patterns(*patterns)
      match{ patterns.any?{|p| p === __response__.status} }
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

    private

    def expand_status_patterns(*patterns)
      patterns.inject([]) {|patterns, pattern|
        case pattern
        when :any
          pattern << (100..599)
        when :user_error
          patterns << (400..499)
        when :server_error
          patterns << (500..599)
        when :error
          patterns << (400..499) << (500..599)
        when :success
          patterns << (200..299)
        else
          patterns << pattern
        end
      }
    end

    def path_matcher(object)
      case object
      when Regexp then method(:match_path_with_regexp)
      else method(:match_path_generic)
      end
    end

    def match_path_with_regexp(pattern, path, captures)
      capture_names = pattern.names
      match_data = pattern.match(path)
      if match_data
        capture_names.each do |name|
          value = match_data[name]
          captures[name] = value if value
        end
      end
    end

    def match_path_generic(pattern, path, captures)
      # We can't capture any values if we don't know what kind of
      # matcher this is
      pattern === path
    end
  end
end
