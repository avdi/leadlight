module Leadlight
  class Link
    attr_reader :service
    attr_reader :rel
    attr_reader :rev
    attr_reader :title
    attr_reader :href

    def initialize(service, href, rel=nil, title=rel, options={})
      @service = service
      @href  = Addressable::URI.parse(href)
      @rel   = rel
      @title = title
      @rev   = options[:rev]
    end

    [:options, :head, :get, :post, :put, :delete, :patch].each do |name|
      define_method(name) do |*args, &block|
        service.public_send(name, href, *args, &block)
      end
    end

    def follow(*args)
      get(*args) do |representation|
        return representation
      end
    end
  end
end
