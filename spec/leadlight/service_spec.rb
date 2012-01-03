require 'spec_helper_lite'
require 'leadlight/service'

module Leadlight
  describe Service do
    subject { klass.new(options) }
    let(:klass) { Class.new do include Service end }
    let(:connection) { stub(:connection, get: response) }
    let(:representation) { stub(:representation) }
    let(:response) { stub(:response, env: env) }
    let(:env) { {leadlight_representation: representation} }
    let(:options) { {}  }

    before do
      subject.stub(connection: connection, url: nil)
    end

    describe '#get' do
      it 'yields the representation from connection.get' do
        connection.should_receive(:get).and_return(response)
        yielded = nil
        subject.get('/') do |r|
          yielded = r
        end
        yielded.should equal(representation)
      end

      it 'returns nothing' do
        subject.get('/').should be_nil
      end

      it 'passes the path to the connection' do
        connection.should_receive(:get).with('/somepath')
        subject.get('/somepath')
      end

      it 'calls the #prepare_request callback' do
        request = stub
        connection.should_receive(:get).and_yield(request)
        subject.should_receive(:prepare_request).with(request)
        subject.get('/')
      end
    end

    describe '#options' do
      it 'returns option values passed to the initializer' do
        it = klass.new(foo: 42, bar: 'baz')
        it.options.should eq(foo: 42, bar: 'baz')
      end
    end

  end
end
