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

    def initialize(service, href, rel=nil, title=rel, options={})
      @service = service
      @href    = Addressable::URI.parse(href)
      @rel     = rel.to_s
      @title   = title.to_s
      @rev     = options[:rev]
      @aliases = Array(options[:aliases])
    end

    HTTP_METHODS.each do |name|
      define_method(name) do |*args, &block|
        service.public_send(name, href, *args, &block)
      end
    end

    def follow(*args)
      get_representation!(*args) do |representation|
        return representation
      end
    end

    def expand(params=nil)
      if params
        dup_with_new_href(expand_uri_with_params(href.dup, params))
      else
        self
      end
    end

    def [](*args)
      expand(*args)
    end

    def to_s
      "Link(#{rel}:#{href})"
    end

    protected

    attr_writer :href

    private

    def expand_uri_with_params(uri, params)
      uri.query_values = ParamHash(params) if params.any?
      uri.normalize
    end

    def dup_with_new_href(uri)
      self.dup.tap do |link|
        link.href = uri
      end
    end
  end
end
