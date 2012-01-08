require 'spec_helper_lite'
require 'leadlight/service'

module Leadlight
  describe Service do
    subject              { klass.new(options)                         }
    let(:klass)          { Class.new do include Service end           }
    let(:connection)     { stub(:connection, get: response)           }
    let(:representation) { stub(:representation)                      }
    let(:response)       { stub(:response, env: env)                  }
    let(:env)            { {leadlight_representation: representation} }
    let(:options)        { {codec: codec}                             }
    let(:codec)          { stub(:codec)                               }
    let(:request)        { stub(:request).as_null_object              }

    before do
      subject.stub(connection: connection, url: nil)
    end

    shared_examples_for "an HTTP client" do |http_method|
      describe "##{http_method}" do
        before do
          Request.stub(:new).and_return(request)
        end

        it 'returns a new request object' do
          Request.should_receive(:new).and_return(request)
          subject.public_send(http_method, '/').should equal(request)
        end

        it 'passes the connection to the request' do
          Request.should_receive(:new).
            with(connection, anything, anything, anything, anything).
            and_return(request)
          subject.public_send(http_method, '/somepath')
        end

        it 'passes the path to the request' do
          Request.should_receive(:new).
            with(anything, '/somepath', anything, anything, anything).
            and_return(request)
          subject.public_send(http_method, '/somepath')
        end

        it 'passes the method to the request' do
          Request.should_receive(:new).
            with(anything, anything, http_method, anything, anything).
            and_return(request)
          subject.public_send(http_method, '/somepath')
        end

        it 'passes the params to the request' do
          params = stub
          Request.should_receive(:new).
            with(anything, anything, anything, params, anything).
            and_return(request)
          subject.public_send(http_method, '/somepath', params)
        end

        it 'passes the body to the request' do
          body = stub
          Request.should_receive(:new).
            with(anything, anything, anything, anything, body).
            and_return(request)
          subject.public_send(http_method, '/somepath', {}, body)
        end

        it 'adds a prepare_request callback' do
          faraday_request = stub(:faraday_request)
          request.stub(:on_prepare_request).and_yield(faraday_request)
          subject.should_receive(:prepare_request).with(faraday_request)
          subject.public_send(http_method, '/')
        end

        context 'given a block' do
          define_method(:do_it) do
            subject.public_send(http_method, '/') do |yielded|
              return yielded
            end
          end

          it 'submits and waits for completion' do
            request.should_receive(:submit_and_wait).and_yield(representation)
            do_it
          end
        end
      end
    end

    it_behaves_like "an HTTP client", :head
    it_behaves_like "an HTTP client", :get
    it_behaves_like "an HTTP client", :post
    it_behaves_like "an HTTP client", :put
    it_behaves_like "an HTTP client", :delete
    it_behaves_like "an HTTP client", :patch

    describe '#options' do
      it 'returns option values passed to the initializer' do
        it = klass.new(foo: 42, bar: 'baz')
        it.options.should eq(foo: 42, bar: 'baz')
      end
    end

    describe '#encode' do
      it 'delegates to the codec' do
        entity = stub
        codec.should_receive(:encode).
          with('CONTENT_TYPE', representation, {foo: 'bar'}).
          and_return(entity)
        subject.encode('CONTENT_TYPE', representation, {foo: 'bar'}).
          should equal(entity)
      end
    end

    describe '#decode' do
      it 'delegates to the codec' do
        entity = stub
        codec.should_receive(:decode).
          with('CONTENT_TYPE', entity, {foo: 'bar'}).
          and_return(representation)
        subject.decode('CONTENT_TYPE', entity, {foo: 'bar'}).
          should equal(representation)
      end
    end
  end
end
