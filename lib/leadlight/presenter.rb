require 'uri'
require 'cgi'
require 'dm-core'

module Leadlight
  class NullObject
    def method_missing(*args, &block)
      self
    end
  end

  class Presenter
    attr_reader :request
    attr_reader :logger

    def self.datamapper_rule
      lambda do |presenter, object, data, view|
        if DataMapper::Resource === object && view == :full
          object.attributes.each do |name, value|
            unless rules.keys.include?(name)
              data[name] = value
            end
          end
        end
      end
    end

    def self.inherited(heir)
      @presenters ||= [self]
      @presenters.unshift(heir)
    end

    def self.presents?(klass)
      @class && klass <= @class
    end

    def self.presents(klass)
      @class = klass
    end

    def self.for(klass, request, options={})
      presenter = @presenters.detect{|p| p.presents?(klass)}
      (presenter && presenter.new(request)) or 
        raise "No presenter found for #{klass.inspect}"
    end

    def self.present(attribute, options={}, &block)
      attribute_alias = options.delete(:as) { attribute }
      views = Array(options.delete(:include_in) { [] })
      views << :full unless views.include?(:full)
      generator = block || lambda{|presenter, object|
        object.send(attribute)
      }
      rule = lambda{|presenter, object, data, view|
        if views.include?(view)
          data[attribute_alias] = generator.call(presenter, object)
        end
      }
      rules[attribute] = rule
    end

    def self.exclude(attribute)
      rules[attribute] = lambda do 
        # NOOP
      end
    end

    def self.rules
      @rules ||= {:__default_dm_rule => datamapper_rule}
    end

    def initialize(request, options={})
      @request = request
      @logger  = options.fetch(:logger){NullObject.new}
    end

    def present_json(object_or_collection, *json_args)
      data = present(object_or_collection)
      data.to_json(*json_args)
    end

    def present(object_or_collection)
      if object_or_collection.respond_to?(:each)
        present_collection(object_or_collection)
      else
        present_object(object_or_collection, :full)
      end
    end

    def present_collection(collection)
      collection.map{|object| 
        begin
          present_object(object, :summary)
        rescue => error
          logger.error "#{error.class} while presenting #{object.inspect}: #{error.message}"
        end
      }
    end

    def present_object(object, view=:full)
      if object.errors.empty?
        present_valid_object(object, view)
      else
        present_invalid_object(object)
      end
    end

    def present_valid_object(object, view = :full)
      data = {}
      self.class.rules.each_pair do |name, rule|
        rule.call(self, object, data, view)
      end
      data
    end

    def present_invalid_object(object)
      fields = object.attributes.keys
      list = object.errors.keys.inject([]) do |errors, field|
        field_errors = object.errors.on(field)
        Array(field_errors).each do |message|
          if fields.include?(field)
            errors << { 'field' => field.to_s, 'message' => message.to_s }
          else
            errors << { 'message' => message.to_s }
          end
        end
        errors
      end
      list.sort_by{|h| h['field'].to_s }
    end

    def url(*components)
      URI.join(base_url, components.join("/")).to_s
    end

    def url_for(object)
      present_valid_object(object)[:url]
    end

    def base_url
      @base_url ||= URI.parse("http://#{request.host}:#{request.port}").to_s
    end

    def escape(string)
      CGI.escape(string.to_s)
    end
  end
end
