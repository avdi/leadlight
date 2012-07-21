require 'forwardable'
require 'leadlight/link'
require 'addressable/template'

module Leadlight
  class LinkTemplate < Link
    extend Forwardable

    def_delegators :href_template, :variables

    def href_template
      @href_template ||= Addressable::Template.new(href.to_s)
    end

    HTTP_METHODS.each do |name|
      define_method(name) do |*args, &block|
        expanded_href = expand(*args).href
        service.public_send(name, expanded_href, &block)
      end
    end

    def expand(*args)
      return self if args.empty?
      mapping = args.last.is_a?(Hash) ? args.pop : {}
      mapping = mapping.inject({}) { |result, (k,v)| result.merge!(k.to_s => v) }
      mapping = href_template.variables.inject(mapping) do |mapping, var|
        mapping.merge!(var => args.shift) unless args.empty?
        mapping
      end
      full_mapping = mapping.dup
      extra_keys = (mapping.keys.map(&:to_s) - href_template.variables)
      extra_params = extra_keys.inject({}) do |params, key|
        params[key] = mapping.delete(key)
        params
      end
      assert_all_variables_mapped(href_template, mapping)
      uri          = href_template.expand(mapping)
      expanded_uri = expand_uri_with_params(uri, extra_params)
      Link.new(service, expanded_uri, rel, title,
               rev: rev, aliases: aliases, expansion_params: full_mapping)
    end

    private

    def assert_all_variables_mapped(template, mapping)
      supplied_keys = mapping.keys.map(&:to_s)
      needed_keys   = template.variables
      missing_keys  = needed_keys - supplied_keys
      if !missing_keys.empty?
        raise ArgumentError,
              "Missing URI template parameters: #{missing_keys.inspect}"
      end
    end
  end
end
