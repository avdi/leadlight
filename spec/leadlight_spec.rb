require 'spec_helper_lite'
require 'leadlight'

describe Leadlight, vcr: true do
  def uri(uri_string)
    Addressable::URI.parse(uri_string)
  end

  def urit(pattern)
    Addressable::Template.new(pattern)
  end

  let(:logger)  { 
    logfile = Pathname('../../log/test.log').expand_path(__FILE__)
    logfile.dirname.mkpath
    Logger.new(logfile) 
  }

  describe 'basic GitHub example' do
    class BasicGithubService
      Leadlight.build_service(self) do
        url 'https://api.github.com'
      end
    end

    subject { session }
    let(:session) { BasicGithubService.session(options) }
    let(:options) { {logger: logger} }

    describe '.root' do
      subject{ session.root }

      it { should be_blank }

      its(:__location__) { should eq(uri('https://api.github.com')) }

      it "should be a 204  no content" do
       subject.__response__.status.should eq(204)
      end

    end
  end

  describe 'tinted GitHub example' do
    class TintedGithubService
      Leadlight.build_service(self) do
        url 'https://api.github.com'

        tint 'root' do
          match_path('/')
          add_link_template '/users/{login}', 'user', 'Find user by login'
        end

        tint 'user' do
          match_content_type('application/json')
          match_class(Hash)
          match{self['type'] == 'User'}
          add_link "#{__location__}/followers", 'followers', 'List followers'
        end
      end
    end

    subject { session }
    let(:session) { TintedGithubService.session(options) }
    let(:options) { {logger: logger} }

    describe '.root' do
      subject{ session.root }

      it { should be_blank }

      its(:__location__) { should eq(uri('https://api.github.com')) }

      it "should be a 204  no content" do
       subject.__response__.status.should eq(204)
      end
    end

    describe 'user link' do
      it 'exists' do
        subject.root.link('user').should be_a(Leadlight::Link)
      end

      it 'links to the expected URL' do
        subject.root.link('user').href.should eq(uri('/users/{login}'))
      end
    end

    describe '#user' do
      it 'has the expected content' do
        user = subject.root.user('avdi')
        user['type'].should eq('User')
        user['location'].should eq('Pennsylvania, USA')
        user['company'].should eq('ShipRise')
        user['name'].should eq('Avdi Grimm')
      end
    end

    describe 'user followers' do
      subject { session.root.user('avdi').followers }

      it { should_not be_empty }

      it 'should have "next" and "last" links' do
        subject.link('next').should be_a(Leadlight::Link)
        subject.link('last').should be_a(Leadlight::Link)
      end

      it 'should be able to follow "next" link' do
        page2 = subject.next
        page2.link('prev').href.path.should eq(subject.__location__.path)
      end

      it 'should be enumerable' do
        followers = []
        subject.each do |f|
          followers << f
        end
        followers.size.should be > 150
      end

      it 'should be enumerable over page boundaries' do
        followers = subject.to_enum.take(61)
        followers.should have(61).items
      end
    end
  end

  describe 'authorized GitHub example', vcr: { match_requests_on: [:method, :uri]}do
    AuthorizedGithubService ||= Leadlight.build_service do
      url 'https://api.github.com'

      # Tints will skip error responses by default
      tint 'errors', :status => :error do
        extend do
          def exception_message
            self['message'] || super
          end
        end
      end

      tint 'root' do
        match_path('/')
        add_link_template '/users/{login}', 'user', 'Find user by login'
        add_link_template '/orgs/{name}',   'organization'
      end

      tint 'auth_scopes' do
        extend do
          def oauth_scopes
            __response__.headers['X-OAuth-Scopes'].to_s.strip.split(/\W+/)
          end
        end
      end

      tint 'organization' do
        match_path(%r{^/orgs/\w+$})
        add_link "#{__location__}/teams", 'teams'

        extend do
          def team_for_name(name)
            teams.get(name)
          end
        end
      end

      tint 'teamlist' do
        match_path(%r{^/orgs/\w+/teams$})

        add_link_set('child', :get) do
          map{|team|
            {href: team['url'], title: team['name']}
          }
        end
      end

      tint 'team' do
        match_template('/teams/{id}')
        
        add_link "#{__location__}/members", 'members'
        add_link_template "#{__location__}/members/{id}", 'member'

        extend do
          def add_member(member_name)
            link('member').put(member_name).submit_and_wait.raise_on_error
          end

          def remove_member(member_name)
            link('member').delete(member_name).submit_and_wait.raise_on_error
          end
        end
      end

      class GithubRepresentation < SimpleDelegator
        def github_type
          self['type']
        end
      end

      # Define a type-mapping which will override the default handling
      # of application/json and instantiate GithubRepresentation
      # objects
      type_mapping "application/json", Object do
        def encode(object, options={})
          encode_with_type("application/json", object.__getobj__, options)
        end

        def decode(content_type, entity_body, options={})
          object = decode_with_type(content_type, entity_body, options)
          GithubRepresentation.new(object)
        end
      end

      on_prepare_request do |event, request|
        # 'request' is the Faraday request being prepared
        #
        # 'event.source' is the Leadlight request, which delegates
        # #service_options to the service
        request.headers['Authorization'] = 
          "Bearer #{event.source.service_options[:oauth2_token]}"
      end

    end

    subject { session }
    let(:session) { AuthorizedGithubService.session(service_options) }
    let(:service_options) { {logger: logger, oauth2_token: test_user_token} }
    let(:test_user_token) { credentials[:github_test_user_token] }

    describe '#user' do
      it 'has the expected content' do
        user = subject.root.user('avdi')
        user['type'].should eq('User')
        user['location'].should eq('Pennsylvania, USA')
        user['company'].should eq('ShipRise')
        user['name'].should eq('Avdi Grimm')
      end

      it 'indicates the expected oath scopes' do
        subject.root.user('avdi').oauth_scopes.should eq(['repo'])
      end
    end

    describe 'test team' do
      subject { session.root.organization('shiprise').team_for_name('Leadlight Test Team') }
      
      it { should be }
    end

    specify "adding and removing team members" do
      user = session.root.user("leadlight-test")
      user.should_not be_empty
      org = session.root.organization('shiprise')
      org.should be_a(GithubRepresentation)
      teams = org.teams
      team = teams.get('Leadlight Test Team')
      team.should be_a(GithubRepresentation)
      team.should_not be_empty
      team.add_member('leadlight-test')
        team.members.map{|m| m['login']}.should include('leadlight-test')
      team.remove_member('leadlight-test')
      team.members.map{|m| m['login']}.should_not include('leadlight-test')
    end
  end
end
