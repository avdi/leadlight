require 'spec_helper_lite'
require 'leadlight/link_template'

module Leadlight
  describe LinkTemplate do
    subject { LinkTemplate.new(service, href, rel, title, options) }
    let(:service) { stub(:service, get: nil) }
    let(:href)    { '/TEST_PATH/{n}/{m}/'   }
    let(:rel)     { 'TEST_REL'     }
    let(:title)   { 'TEST_TITLE'   }
    let(:options) { {}             }
    let(:mapping) { {'n' => 'N_VALUE', 'm' => 'M_VALUE'} }
    let(:values)  { mapping.values }

    describe '#follow' do
      it 'calls service.get with the expanded href' do
        service.should_receive(:get).with('/TEST_PATH/23/42/')
        subject.follow(23,42)
      end

      it 'can accept a hash for template parameters' do
        service.should_receive(:get).with('/TEST_PATH/AA/BB/')
        subject.follow(:n => 'AA', 'm' => 'BB')
      end

      it 'returns the result of the get' do
        request = stub
        result = stub
        service.should_receive(:get).
          and_yield(result).
          and_return(request)
        subject.follow(23,42).should equal(result)
      end

      it 'returns nothing' do
        subject.follow(*values).should be_nil
      end
    end
  end
end
