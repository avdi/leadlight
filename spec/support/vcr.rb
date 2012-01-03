require 'vcr'

VCR.configure do |c|
  c.hook_into :faraday
  c.cassette_library_dir     = 'spec/cassettes'
  c.filter_sensitive_data('<AUTH FILTERED>') {|interaction|
    Array(interaction.request.headers['Authorization']).first
  }
  c.configure_rspec_metadata!
  c.ignore_request {|req|
    Addressable::URI.parse(req.uri).host == 'example.com'
  }
  c.default_cassette_options = {
    match_requests_on: [:method, :uri, :headers],
    record: :new_episodes
  }
end

