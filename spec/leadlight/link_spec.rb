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

      it 'returns the result of the get' do
        request = stub
        result = stub
        service.should_receive(:get).
          and_yield(result).
          and_return(request)
        subject.follow.should equal(result)
      end
    end

    def self.delegates_to_service(method_name)
      it "delegates ##{method_name} to the service" do
        yielded        = :nothing
        args           = [:foo, :bar]
        request        = stub(:request)
        representation = stub(:representation)
        service.should_receive(method_name).
          with(subject.href, *args).
          and_yield(representation).
          and_return(request)
        subject.public_send(method_name, *args) do |rep|
          yielded = rep
        end.should equal(request)
      end
    end

    delegates_to_service :get
    delegates_to_service :post
    delegates_to_service :head
    delegates_to_service :options
    delegates_to_service :put
    delegates_to_service :delete
    delegates_to_service :patch
  end
end
