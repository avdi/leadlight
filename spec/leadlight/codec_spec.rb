require 'spec_helper_lite'
require 'leadlight/codec'

module Leadlight
  describe Codec do
    let(:representation) { stub(:representation) }
    let(:entity_body)    { stub(:entity_body)    }

    it 'decodes JSON with multi_json' do
      MultiJson.should_receive(:decode).
        with(entity_body, anything).
        and_return(representation)
      subject.decode('application/json', entity_body).
        should equal(representation)
    end

    it 'decodes types ending in +json as JSON' do
      MultiJson.should_receive(:decode).
        with(entity_body, anything).
        and_return(representation)
      subject.decode('application/vnc.example.user+json foo=bar', entity_body).
        should equal(representation)
    end

    it 'decodes text/plain as a string' do
      subject.decode('text/plain', entity_body).should eq(entity_body)
    end

    it 'barfs on unrecognized content-type' do
      expect{ subject.decode('xyzzy', entity_body) }.
        to raise_error(ArgumentError)
    end

    it 'ignores junk after the content type' do
      subject.decode('text/plain foo=bar', entity_body).should eq(entity_body)
    end

    it 'ignores whitespace in the content type' do
      subject.decode('  text/plain foo=bar', entity_body).should eq(entity_body)
    end

    it 'passes options to the JSON decoder' do
      MultiJson.should_receive(:decode).
        with(anything, {foo: 42})
      subject.decode('application/json', entity_body, foo: 42)
    end
  end
end
