require 'spec_helper_lite'
require 'leadlight/connection_builder'
require 'leadlight/service_middleware'

module Leadlight
  describe ConnectionBuilder do
    describe '#call' do
      subject {
        described_class.new do |cxn|
          cxn.url url
          cxn.service service
        end
      }
      let(:cxn)             { double(:cxn) }
      let(:url)             { double(:url, to_s: "STRINGIFIED_URL") }
      let(:faraday_builder) { double(:faraday_builder) }
      let(:service)         { double(:service,
                                     connection_stack: connection_stack,
                                     logger: double(:logger) ) }
      let(:connection_stack){
        ->(builder) { probe(:connection_stack, builder) }
      }
      let(:common_stack){
        ->(builder) { probe(:common_stack, builder) }
      }

      it 'creates and returns a new Faraday connection' do
        Faraday.should_receive(:new).and_return(cxn)
        subject.call.should equal(cxn)
      end

      it 'passes the url to the new connection' do
        Faraday.should_receive(:new).with(url: "STRINGIFIED_URL")
        subject.call
      end

      it 'builds a middleware stack in the expected order' do
        Faraday.stub(:new).and_yield(faraday_builder)
        Leadlight.stub(:common_connection_stack => common_stack)
        faraday_builder.should_receive(:use).
          with(Leadlight::ServiceMiddleware, service: service).
          ordered
        service.should_receive(:probe).
          with(:connection_stack, faraday_builder).
          ordered
        faraday_builder.should_receive(:use).
          with(Faraday::Response::Logger, service.logger).
          ordered
        service.should_receive(:probe).
          with(:common_stack, faraday_builder).
          ordered
        subject.call
      end
    end
  end
end
