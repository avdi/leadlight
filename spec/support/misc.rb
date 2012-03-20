module MiscSpecHelpers
  def u(*args)
    Addressable::URI.parse(*args)
  end
end

RSpec.configure do |config|
  config.include(MiscSpecHelpers)
end
