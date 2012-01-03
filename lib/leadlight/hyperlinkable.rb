require 'addressable/uri'
require 'addressable/template'
require 'link_header'
require 'leadlight/link'
require 'leadlight/link_template'

module Leadlight
  module Hyperlinkable
    def self.extended(representation)
      super(representation)
      representation.add_link(representation.__response__.env[:url],
                              'self', 'self', rev: 'self')
      representation.add_links_from_headers
    end

    def links
      @__links__ ||= {}
    end

    def link(rel)
      links[rel]
    end

    def add_link(url, rel=nil, title=rel, options={})
      link = Link.new(__service__, url, rel, title, options)
      define_link_helper(rel) if rel
      links[rel] = link
    end

    def add_link_template(template, rel=nil, title=rel, options={})
      link = LinkTemplate.new(__service__, template, rel, title, options)
      define_link_helper(rel) if rel
      links[rel] = link
    end

    def add_links_from_headers
      raw_link_header = __response__.env[:response_headers]['Link']
      link_header = LinkHeader.parse(raw_link_header.to_s)
      link_header.links.each do |link|
        add_link(link.href, link['rel'], link['rel'])
      end
    end

    private

    def __link_helper_module__
      @__link_helper_module__ ||=
        begin
          mod = Module.new
          self.extend(mod)
          mod
        end
    end

    def define_link_helper(name)
      __link_helper_module__.module_eval do
        define_method(name) do |*args|
          links[name].follow(*args) do |result|
            return result
          end
        end
      end
    end


  end
end
