require 'leadlight/tint_helper'

module Leadlight
  class Tint < Module
    attr_reader :name
    def initialize(name, &block)
      @name = @tint_name  = name
      tint = self
      super(){
        define_method(:__apply_tint__) do
          super()
          helper = TintHelper.new(self, tint)
          helper.exec_tint(&block)
        end
      }
    end

    def inspect
      "#<Leadlight::Tint:#{@tint_name}>"
    end

    def to_s
      inspect
    end
  end
end
