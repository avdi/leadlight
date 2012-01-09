require 'leadlight/link'
require 'addressable/template'

module Leadlight
  class LinkTemplate < Link

    def href_template
      @href_template ||= Addressable::Template.new(href.to_s)
    end

    HTTP_METHODS.each do |name|
      define_method(name) do |*args, &block|
        expanded_href = expand(args)
        service.public_send(name, expanded_href, *args, &block)
      end
    end

    def expand(args)
      mapping = args.last.is_a?(Hash) ? args.pop : {}
      mapping = mapping.inject({}) { |result, (k,v)| result.merge!(k.to_s => v) }
      mapping = href_template.variables.inject(mapping) do |mapping, var|
        mapping.merge!(var => args.shift) unless args.empty?
        mapping
      end
      extra_keys = (mapping.keys.map(&:to_s) - href_template.variables)
      extra_params = extra_keys.inject({}) do |params, key|
        params[key] = mapping.delete(key)
        params
      end
      assert_all_variables_mapped(href_template, mapping)
      args.push extra_params unless extra_params.empty?
      href_template.expand(mapping).to_s
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
