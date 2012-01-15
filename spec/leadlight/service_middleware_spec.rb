require 'spec_helper_lite'
require 'leadlight/service_middleware'
require 'faraday'

module Leadlight
  describe ServiceMiddleware do
    let(:test_stack) {
      Faraday.new(url: 'http://example.com') do |b|
        b.use described_class, service: service
        b.adapter :test, faraday_stubs
      end
    }

    subject { described_class.new(app, service: service) }
    let(:service) { stub(url: 'http://example.com', tints: []) }
    let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:app)     { ->(env){stub(on_complete: nil)} }
    let(:response) { [200, {}, ''] }
    let(:result_env) {
      do_get('/').env
    }
    let(:representation) { result_env[:leadlight_representation] }
    let(:leadlight_request) { stub(:leadlight_request, represent: stub) }

    def do_get(path)
      test_stack.get(path) do |request|
        request.options[:leadlight_request] = leadlight_request
      end
    end

    before do
      faraday_stubs.get('/') {response}
    end

    it 'adds :leadlight_service to env before app' do
      do_get('/').env[:leadlight_service].should equal(service)
    end

    it 'requests JSON, then YAML, then XML, then HTML' do
      result_env[:request_headers]['Accept'].
        should eq('application/json, text/x-yaml, application/xml, application/xhtml+xml, text/html, text/plain')
    end
  end
end
