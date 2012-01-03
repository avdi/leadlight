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
      test_stack.get('/').env
    }
    let(:representation) { result_env[:leadlight_representation] }

    before do
      faraday_stubs.get('/') {response}
    end

    it 'adds :leadlight_service to env before app' do
      test_stack.get('/').env[:leadlight_service].should equal(service)
    end

    it 'extends the representation with Representation' do
      representation.should be_a(Representation)
    end

    it 'makes the representation hyperlinkable' do
      representation.should be_a(Hyperlinkable)
    end

    it 'requests JSON, then YAML, then XML, then HTML' do
      result_env[:request_headers]['Accept'].
        should eq('application/json, text/x-yaml, application/xml, application/xhtml+xml, text/html, text/plain')
    end

    context 'with a no-content response' do
      let(:response) { [204, {}, ''] }
      let(:result_env) {
        test_stack.get('/').env
      }

      it 'sets :leadlight_representation to a Blank' do
        result_env[:leadlight_representation].should be_a(Blank)
      end
    end

    context 'with a blank JSON response' do
      let(:response) {
        [200, {'Content-Type' => 'application/json', 'Content-Length' => '0'}, '']
      }
      let(:result_env) {
        test_stack.get('/').env
      }

      it 'sets :leadlight_representation to a Blank' do
        result_env[:leadlight_representation].should be_a(Blank)
      end
    end

    context 'with a non-blank JSON response' do
      let(:response) {
        [200, {'Content-Type' => 'application/json', 'Content-Length' => '7'}, '[1,2,3]']
      }
      let(:result_env) {
        test_stack.get('/').env
      }
      it 'sets :leadlight_representation to the result of parsing the JSON' do
        result_env[:leadlight_representation].should eq([1,2,3])
      end
    end
  end
end
