require 'yaml'

module CredentialsTestHelpers
  def credentials
    credentials_path = Pathname('../../credentials.yml').expand_path(__FILE__)
    @loaded_credentials ||= if credentials_path.readable?
                              YAML.load_file(credentials_path) || {}
                            else
                              {}
                            end
    @credentials ||= Hash.new do |h,k|
      h[k] = "MISSING_CREDENTIAL_KEY_#{k}"
      unless ENV['TRAVIS']
        warn "Missing key #{k.inspect} from #{credentials_path}"
      end
    end.merge!(@loaded_credentials)
  rescue LoadError, SystemCallError, KeyError => e
    pending e.message
  end
end

RSpec.configure do |config|
  config.include(CredentialsTestHelpers)
end
