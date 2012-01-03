require 'fattr'
require 'leadlight/entity'
require 'addressable/template'
require 'leadlight/tint'

module Leadlight
  class Type < Module
    attr_reader :name
    attr_reader :service
    fattr       :enctype
    fattr       :link_to_create

    def initialize(name, service, &body)
      @name         = name
      @service      = service      
      @builder      = Object.method(:new)
      @enctype = 'application/json'
      super() do
        instance_exec &preamble
        instance_exec &body
      end
    end

    def inspect
      "#<Leadlight::Type:#{name}>"
    end

    def to_s
      "Type(#{name})"
    end

    def builder(&block)
      @builder = block
    end

    def build(*args)
      obj = @builder.call(*args).extend(self)
      yield obj if block_given?
      obj
    end

    def to_entity(object)
      Entity.new(enctype)
    end

    def encode(representation, options={})
      encoder = options.fetch(:encoder){ representation.__service__ }
      encoder.encode(enctype, representation, options)
    end

    def extended(object)
      super
      if link_to_create
        object.add_link(link_to_create, 'create', "Create a new #{name}")
      end
    end

    def tint
      @tint ||= Tint.new("type:#{name}") do
      end
    end
    
    private

    def preamble
      the_type = self
      proc {
        define_method(:__type__){ the_type }
      }
    end
  end
end
