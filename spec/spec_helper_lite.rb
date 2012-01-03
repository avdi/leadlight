ENV["RAILS_ENV"] ||= 'test'
require 'rspec/autorun'
require 'English'
ROOT = File.expand_path('../..', __FILE__)
Dir[File.join(ROOT, "spec/support/**/*.rb")].each {|f| require f}
$LOAD_PATH.unshift(File.expand_path('lib', ROOT))
