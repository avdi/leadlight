## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'leadlight'
  s.version           = '0.0.5'
  s.date              = '2012-02-15'
  s.rubyforge_project = 'leadlight'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Rose colored stained glass windows for HTTP."
  s.description = "Rose colored stained glass windows for HTTP."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Avdi Grimm"]
  s.email    = 'avdi@avdi.org'
  s.homepage = 'https://github.com/avdi/leadlight'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  ## s.rdoc_options = ["--charset=UTF-8"]
  ## s.extra_rdoc_files = %w[README LICENSE]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  ## s.add_dependency('DEPNAME', [">= 1.1.0", "< 2.0.0"])
  s.add_dependency 'addressable'
  s.add_dependency 'faraday'
  s.add_dependency 'fattr'
  s.add_dependency 'link_header'
  s.add_dependency 'multi_json', '~> 1.0.4'
  s.add_dependency 'mime-types'
  s.add_dependency 'hookr'

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  ## s.add_development_dependency('DEVDEPNAME', [">= 1.1.0", "< 2.0.0"])
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'vcr', '~> 2.0.0.rc1'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-bundler'
  s.add_development_dependency 'ruby-debug19'

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    Guardfile
    README.md
    Rakefile
    default.gems
    leadlight.gemspec
    lib/leadlight.rb
    lib/leadlight/basic_converter.rb
    lib/leadlight/blank.rb
    lib/leadlight/codec.rb
    lib/leadlight/entity.rb
    lib/leadlight/enumerable_representation.rb
    lib/leadlight/errors.rb
    lib/leadlight/header_helpers.rb
    lib/leadlight/hyperlinkable.rb
    lib/leadlight/link.rb
    lib/leadlight/link_template.rb
    lib/leadlight/representation.rb
    lib/leadlight/request.rb
    lib/leadlight/service.rb
    lib/leadlight/service_class_methods.rb
    lib/leadlight/service_middleware.rb
    lib/leadlight/tint.rb
    lib/leadlight/tint_helper.rb
    lib/leadlight/type_map.rb
    spec/cassettes/Leadlight/authorized_GitHub_example/_user/has_the_expected_content.yml
    spec/cassettes/Leadlight/authorized_GitHub_example/_user/indicates_the_expected_oath_scopes.yml
    spec/cassettes/Leadlight/authorized_GitHub_example/adding_and_removing_team_members.yml
    spec/cassettes/Leadlight/authorized_GitHub_example/adding_and_removing_teams.yml
    spec/cassettes/Leadlight/authorized_GitHub_example/test_team/.yml
    spec/cassettes/Leadlight/basic_GitHub_example/_root/.yml
    spec/cassettes/Leadlight/basic_GitHub_example/_root/__location__/.yml
    spec/cassettes/Leadlight/basic_GitHub_example/_root/should_be_a_204_no_content.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/_root/.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/_root/__location__/.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/_root/should_be_a_204_no_content.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/_user/has_the_expected_content.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/bad_links/enables_custom_error_matching.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/bad_links/should_raise_ResourceNotFound.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_followers/.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_followers/should_be_able_to_follow_next_link.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_followers/should_be_enumerable.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_followers/should_be_enumerable_over_page_boundaries.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_followers/should_have_next_and_last_links.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_link/exists.yml
    spec/cassettes/Leadlight/tinted_GitHub_example/user_link/links_to_the_expected_URL.yml
    spec/leadlight/codec_spec.rb
    spec/leadlight/hyperlinkable_spec.rb
    spec/leadlight/link_spec.rb
    spec/leadlight/link_template_spec.rb
    spec/leadlight/representation_spec.rb
    spec/leadlight/request_spec.rb
    spec/leadlight/service_middleware_spec.rb
    spec/leadlight/service_spec.rb
    spec/leadlight/tint_helper_spec.rb
    spec/leadlight/tint_spec.rb
    spec/leadlight/type_map_spec.rb
    spec/leadlight_spec.rb
    spec/spec_helper_lite.rb
    spec/support/credentials.rb
    spec/support/vcr.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
