require 'addressable/uri'
require 'addressable/template'
require 'link_header'
require 'leadlight/link'
require 'leadlight/link_template'
require 'forwardable'
require 'fattr'

module Leadlight
  module Hyperlinkable
    def self.extended(representation)
      super(representation)
      representation.add_link(representation.__location__,
                              'self', 'self', rev: 'self')
      representation.add_links_from_headers
    end

    def links(key=:none)
      if :none == key
        @__links__ ||= LinkSet.new
      else
        links[key]
      end
    end

    def link(key, *expand_args, &fallback)
      link = links.at(key, &fallback)
      link && link.expand(*expand_args)
    end

    def add_link(url, rel=nil, title=rel, options={})
      template = LinkTemplate.new(__service__, url, rel, title, options)
      link     = template.expand(captures_for_variables(__captures__,
                                                        template.variables))
      define_link_helper(rel) if rel
      links << link
    end

    def add_link_template(template, rel=nil, title=rel, options={})
      link = LinkTemplate.new(__service__, template, rel, title, options)
      define_link_helper(rel) if rel
      links << link
    end

    def add_link_set(rel=nil, helper_name=rel)
      default_link_attributes = {
        rel: rel
      }
      yield.each do |link_attributes|
        attributes = default_link_attributes.merge(link_attributes)
        define_link_set_helper(rel, helper_name) if helper_name
        links << Link.new(__service__,
                          attributes[:href],
                          attributes[:rel],
                          attributes[:title],
                          attributes)
      end
    end

    def add_links_from_headers
      raw_link_header = __response__.env[:response_headers]['Link']
      link_header = LinkHeader.parse(raw_link_header.to_s)
      link_header.links.each do |link|
        add_link(link.href, link['rel'], link['rel'])
      end
    end

    private

    class LinkSet
      extend Forwardable
      include Enumerable
      fattr(:links) { Set.new }

      def_delegators :links, :<<, :push, :size, :length, :empty?, :each,
                             :initialize

      # Match links on rel or title
      def [](key)
        self.class.new(select(&link_matcher(key)))
      end

      # Matches only one link
      def at(key, &fallback)
        fallback ||= -> do raise KeyError, "No link matches #{key.inspect}" end
        detect(fallback, &link_matcher(key))
      end

      private

      def link_matcher(key)
        ->(link) {
          key === link.rel   ||
          key === link.title ||
          link.aliases.any?{|a| key === a}
        }
      end
    end

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
          link(name).follow(*args) do |result|
            return result
          end
        end
      end
    end

    def define_link_set_helper(rel, name)
      __link_helper_module__.module_eval do
        define_method(name) do |key, *args|
          links(rel).at(key).follow(*args) do |result|
            return result
          end
        end
      end
    end

    def captures_for_variables(captures, variables)
      variables.each_with_object({}) do |key, h|
        h[key] = captures[key] if captures[key]
      end
    end
  end
end
