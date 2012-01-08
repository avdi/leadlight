source 'http://rubygems.org'

gemspec

# I fear there's no reasonable way to do conditional dependencies like this in 
# a gemspec.
gem 'rb-inotify' if RUBY_PLATFORM =~ /linux/i
gem 'libnotify' if RUBY_PLATFORM =~ /linux/i

