require 'spec_helper_lite'
require 'leadlight/param_hash'

module Leadlight
  describe ParamHash do
    include Leadlight
    it 'converts values to strings' do
      result = ParamHash(:foo => 123, :bar => :baz, :buz => 2.3)
      result.should eq({:foo => "123", :bar => "baz", :buz => "2.3"})
    end

    it 'converts arrays to arrays of strings' do
      result = ParamHash(:foo => [:bar, 123, 3.14])
      result.should eq(:foo => ["bar", "123", "3.14"])
    end


    it 'converts values recursively' do
      result = ParamHash(:h =>
                         {:foo => 123, :bar => :baz, :buz => 2.3})
      result.should eq(:h =>
                       {:foo => "123", :bar => "baz", :buz => "2.3"})
    end

  end
end
