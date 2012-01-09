module Leadlight
  class Link
    HTTP_METHODS = [
      :options, :head, :get, :get_representation!, :post, :put, :delete, :patch
    ]

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

    [:options, :head, :get, :get_representation!, :post, :put, :delete, :patch].each do |name|
      define_method(name) do |*args, &block|
        service.public_send(name, href, *args, &block)
      end
    end

    def follow(*args)
      get_representation!(*args) do |representation|
        return representation
      end
    end
  end
end
