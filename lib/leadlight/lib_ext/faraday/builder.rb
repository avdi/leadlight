module Faraday
  class Builder
    class Handler
      attr_reader :args

      def adapter?
        klass.respond_to?(:adapter?) && klass.adapter?
      end

    end

    def build(options = {})
      raise_if_locked
      clear unless options[:keep]
      yield self if block_given?
    end

    def clear
      @handlers.clear
    end

    def adapter(key=nil, *args, &block)
      if [key, *args, block].none?
        find_adapter
      else
        use_symbol(Faraday::Adapter, key, *args, &block)
      end
    end

    def has_adapter?
      !!find_adapter
    end

    def adapter=(adapter_args)
      clear_adapters
      adapter(*adapter_args)
    end

    def find_adapter
      @handlers.detect{|h| h.adapter?}
    end

    def clear_adapters
      @handlers.delete_if{|h| h.adapter?}
    end
  end
end
