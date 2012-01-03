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

    def follow(&block)
      result = get(href, &block)
    end

    private

    def get(path, &block)
      result = service.get(path, &block)
      nil
    end
  end
end
