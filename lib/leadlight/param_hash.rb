require 'delegate'

module Leadlight
  def ParamHash(hash)
    case hash
    when ParamHash then hash
    else ParamHash.new(hash)
    end
  end
  module_function :ParamHash

  class ParamHash < DelegateClass(Hash)
    def initialize(hash)
      super(transform_hash(Hash[hash], :deep => true) {|h,k,v|
              h[k] = transform_value(v)
            })
    end

    private

    def transform_hash(original, options={}, &block)
      original.inject({}){|result, (key,value)|
        value = if (options[:deep] && Hash === value)
                  transform_hash(value, options, &block)
                else
                  value
                end
        block.call(result,key,value)
        result
      }
    end

    def transform_value(value)
      case value
      when ParamHash then value
      when Hash      then self.class.new(value)
      when Array     then value.map(&:to_s)
      else value.to_s
      end
    end
  end
end
