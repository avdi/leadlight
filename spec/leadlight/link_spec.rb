require 'spec_helper_lite'
require 'leadlight/link'

module Leadlight
  describe Link do
    subject { Link.new(service, href, rel, title, options) }
    let(:service) { stub(:service, get: nil) }
    let(:href)    { '/TEST_PATH'   }
    let(:rel)     { 'TEST_REL'     }
    let(:title)   { 'TEST_TITLE'   }
    let(:options) { {}             }

    describe '#follow' do
      it 'calls service.get with the href' do
        service.should_receive(:get).with(Addressable::URI.parse(href))
        subject.follow
      end

      it 'yields the result of the get' do
        result = stub
        yielded_result = nil
        service.should_receive(:get).and_yield(result)
        subject.follow do |r|
          yielded_result = r
        end
        yielded_result.should equal(result)
      end

      it 'returns nothing' do
        subject.follow.should be_nil
      end
    end
  end
end
