require 'spec_helper_lite'
require 'leadlight/null_link'

module Leadlight
  describe NullLink do
    subject {
      NullLink.new("http://example.org/z/y/?foo=123&bar=456&bar=789")
    }

    it 'derives params from URL query string' do
      subject.params.should eq("foo" => "123", "bar" => "789")
    end
  end
end
