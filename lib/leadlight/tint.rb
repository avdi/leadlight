require 'leadlight/tint_helper'

module Leadlight
  class Tint < Module
    attr_reader :name
    def initialize(name, options={}, &block)
      @name = @tint_name  = name
      status_patterns = Array(options.fetch(:status) { :success })
      tint = self
      super(){
        define_method(:__apply_tint__) do
          super()
          helper = TintHelper.new(self, tint)
          helper.exec_tint do
            match_status(*status_patterns)
            instance_eval(&block)
          end
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
