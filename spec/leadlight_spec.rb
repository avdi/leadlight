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
        subject.root.links['user'].should be_a(Leadlight::Link)
      end

      it 'links to the expected URL' do
        subject.root.links['user'].href.should eq(uri('/users/{login}'))
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
        subject.links['next'].should be_a(Leadlight::Link)
        subject.links['last'].should be_a(Leadlight::Link)
      end

      it 'should be able to follow "next" link' do
        page2 = subject.next
        page2.links['prev'].href.path.should eq(subject.__location__.path)
      end

      it 'should be enumerable' do
        followers = []
        subject.each do |f|
          followers << f
        end
        followers.should have(171).items
      end

      it 'should be enumerable over page boundaries' do
        followers = subject.to_enum.take(61)
        followers.should have(61).items
      end
    end
  end

  describe 'authorized GitHub example', vcr: { match_requests_on: [:method, :uri]}do
    class AuthorizedGithubService
      Leadlight.build_service(self) do
        url 'https://api.github.com'

        tint 'root' do
          match_path('/')
          add_link_template '/users/{login}', 'user', 'Find user by login'
        end

        tint 'auth_scopes' do
          extend do
            def oauth_scopes
              __response__.headers['X-OAuth-Scopes'].to_s.strip.split(/\W+/)
            end
          end
        end
      end

      def prepare_request(request)
        request.headers['Authorization'] = "Bearer #{service_options[:oauth2_token]}"
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
  end
end
