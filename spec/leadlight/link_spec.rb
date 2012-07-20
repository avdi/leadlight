require 'spec_helper_lite'
require 'leadlight/link'

module Leadlight
  describe Link do
    include LinkMatchers

    subject { Link.new(service, href, rel, title, options) }
    let(:service) { stub(:service, get: nil) }
    let(:href)    { '/TEST_PATH'   }
    let(:rel)     { 'TEST_REL'     }
    let(:title)   { 'TEST_TITLE'   }
    let(:options) { {}             }

    it { should expand_to('/TEST_PATH?foo=bar').given(:foo => 'bar') }
    it {
      should expand_to('/TEST_PATH?foo=bar&x=42').
        given(:foo => 'bar', "x" => 42)
    }
    it {
      should expand_to('/TEST_PATH?foo[0]=123&foo[1]=456').
        given(:foo => [123,456])
    }

    describe '#expand' do
      it 'returns self given no arguments' do
        subject.expand.should equal(subject)
      end
    end

    describe '#follow' do
      it 'calls service.get with the href' do
        service.should_receive(:get_representation!).with(Addressable::URI.parse(href), anything)
        subject.follow
      end

      it 'returns the result of the get' do
        request = stub
        result = stub
        service.should_receive(:get_representation!).
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
          with(subject.href, *args, anything).
          and_yield(representation).
          and_return(request)
        subject.public_send(method_name, *args) do |rep|
          yielded = rep
        end.should equal(request)
      end

      it "adds itself to the options for ##{method_name}" do
        yielded        = :nothing
        args           = [:foo, :bar, {baz: "buz"}]
        request        = stub(:request)
        representation = stub(:representation)
        service.should_receive(method_name).
          with(subject.href, :foo, :bar, {baz: "buz", link: subject})
        subject.public_send(method_name, *args)
      end

      it "adds missing request options hash to calls to ##{method_name}" do
        yielded        = :nothing
        args           = [:foo, :bar]
        request        = stub(:request)
        representation = stub(:representation)
        service.should_receive(method_name).
          with(subject.href, :foo, :bar, {link: subject})
        subject.public_send(method_name, *args)
      end
    end

    delegates_to_service :get
    delegates_to_service :post
    delegates_to_service :head
    delegates_to_service :options
    delegates_to_service :put
    delegates_to_service :delete
    delegates_to_service :patch


    describe '#params' do
      context 'when explicitly specified' do
        it 'gives explicit params priority over query params' do
          href = "/somepath?foo=baz&fizz=buzz"
          link = Link.new(service, href, rel, title, :expansion_params => {:foo => 'bar'})
          link.params.should eq('foo' => 'bar', 'fizz' => 'buzz')
        end
      end
    end
  end
end
