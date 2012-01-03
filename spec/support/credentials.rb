require 'yaml'

module CredentialsTestHelpers
  def credentials
    credentials_path = Pathname('../../credentials.yml').expand_path(__FILE__)
    @credentials ||= Hash.new do |h,k|
      pending "Missing key #{k.inspect} from #{credentials_path}"
    end.merge!(YAML.load_file(credentials_path) || {})
  rescue LoadError, SystemCallError, KeyError => e
    pending e.message
  end
end

RSpec.configure do |config|
  config.include(CredentialsTestHelpers)
end
