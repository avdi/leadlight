require 'leadlight/link'
require 'addressable/template'

module Leadlight
  class LinkTemplate < Link

    def href_template
      @href_template ||= Addressable::Template.new(href.to_s)
    end

    [:options, :head, :get, :post, :put, :delete, :patch].each do |name|
      define_method(name) do |*args, &block|
        expanded_href = expand(args)
        service.public_send(name, expanded_href, *args, &block)
      end
    end

    def expand(args)
      mapping = args.last.is_a?(Hash) ? args.pop : {}
      mapping = href_template.variables.inject(mapping) do |mapping, var|
        break mapping if args.empty?
        mapping.merge!(var => args.shift)
      end
      assert_all_variables_mapped(href_template, mapping)
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
