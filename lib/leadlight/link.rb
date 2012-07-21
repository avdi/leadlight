require 'addressable/uri'
require 'addressable/template'
require 'leadlight/param_hash'

module Leadlight
  class Link
    include ::Leadlight

    HTTP_METHODS_WITH_BODY    = [:post, :put, :patch]
    HTTP_METHODS_WITHOUT_BODY = [
      :options, :head, :get, :get_representation!, :delete
    ]
    HTTP_METHODS = HTTP_METHODS_WITHOUT_BODY + HTTP_METHODS_WITH_BODY

    attr_reader :service
    attr_reader :rel
    attr_reader :rev
    attr_reader :title
    attr_reader :href
    attr_reader :aliases
    attr_reader :options

    # Expansion params have no effect on the Link. They exist to keep
    # a record of how this particular Link instance was constructed,
    # if it was constructed via expansion.
    attr_reader :expansion_params

    def initialize(service, href, rel=nil, title=rel, options={})
      @options = options
      @service = service
      @href    = Addressable::URI.parse(href)
      @rel     = rel.to_s
      @title   = title.to_s
      @rev     = options[:rev]
      @aliases = Array(options[:aliases])
      self.expansion_params = options.fetch(:expansion_params) { {} }
    end

    HTTP_METHODS_WITHOUT_BODY.each do |name|
      define_method(name) do |*args, &block|
        request_options = args.last.is_a?(Hash) ? args.pop : {}
        request_options[:link] = self
        service.public_send(name, href, nil, *args, request_options, &block)
      end
    end

    HTTP_METHODS_WITH_BODY.each do |name|
      define_method(name) do |*args, &block|
        request_options = if args.size > 1 && args.last.is_a?(Hash)
                            args.pop
                          else
                            {}
                          end
        body = args.shift
        request_options[:link] = self
        service.public_send(name, href, body, *args, request_options, &block)
      end
    end

    def follow(*args)
      get_representation!(*args) do |representation|
        return representation
      end
    end

    def expand(expansion_params=nil)
      if expansion_params
        dup_with_new_href(expand_uri_with_params(href.dup, expansion_params), expansion_params)
      else
        self
      end
    end

    def [](*args)
      expand(*args)
    end

    def to_s
      "Link(#{rel}:#{href}#{inspect_expansion_params})"
    end

    def params
      extracted_params.merge(expansion_params)
    end

    protected

    attr_writer :href

    def expansion_params=(new_params)
      @expansion_params = new_params.each_with_object({}){|(k,v),h|
        h[k.to_s] = v.to_s
      }
    end

    private

    def expand_uri_with_params(uri, uri_params)
      uri.query_values = ParamHash(uri_params) if uri_params.any?
      uri.normalize
    end

    def dup_with_new_href(uri, expansion_params={})
      self.dup.tap do |link|
        link.href = uri
        link.expansion_params = expansion_params
      end
    end

    def inspect_expansion_params
      if expansion_params.empty?
        ""
      else
        " [#{expansion_params.inspect}]"
      end
    end

    def extracted_params
      href.query_values || {}
    end
  end
end
