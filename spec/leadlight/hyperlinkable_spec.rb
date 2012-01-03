require 'spec_helper_lite'
require 'leadlight/hyperlinkable'

module Leadlight
  describe Hyperlinkable do
    subject { representation.extend(Hyperlinkable) }
    let(:representation) { Object.new }
    let(:response) { stub(:response, env: env) }
    let(:response_url) { Addressable::URI.parse('/foo') }
    let(:env) {
      {
        url: '/foo',
        leadlight_service: service,
        :response_headers => headers
      }
    }
    let(:service) { stub(url: 'http://example.com') }
    let(:headers) { {'Link' => links} }
    let(:links) {
      '<https://api.github.com/users/avdi/followers?page=2>; rel="next",'\
      ' <https://api.github.com/users/avdi/followers?page=6>; rel="last"'
    }

    before do
      representation.stub(__response__: response, __service__: service)
    end

    describe '.extend' do

      it 'adds itself to the representation' do
        subject.should be_a(Hyperlinkable)
      end

      it 'adds a self link' do
        subject.link('self').should be_a(Link)
        subject.link('self').href.to_s.should eq('/foo')
        subject.link('self').rel.should eq('self')
        subject.link('self').rev.should eq('self')
        subject.link('self').title.should eq('self')
      end

      it 'adds links from Link header' do
        subject.link('next').href.to_s.
          should eq('https://api.github.com/users/avdi/followers?page=2')
        subject.link('last').href.to_s.
          should eq('https://api.github.com/users/avdi/followers?page=6')
      end

    end

    describe '#add_link' do
      it 'adds a link' do
        expect { subject.add_link('/foo') }.to change{ subject.links.size }.by(1)
      end

      it 'expands links' do
        subject.add_link('/parent', 'parent')
        subject.link('parent').href.to_s.should eq('/parent')
      end

      it 'adds a Link' do
        subject.add_link('/parent', 'parent')
        subject.links['parent'].should be_a(Link)
      end

      it 'adds a link helper' do
        subject.add_link('/parent', 'parent')
        service.should_receive(:get).with(Addressable::URI.parse('/parent'))
        subject.parent
      end
    end

    describe '#add_link_template' do
      it 'adds a link' do
        expect { subject.add_link_template('/foo/{id}') }.to change{ subject.links.size }.by(1)
      end

      it 'expands links' do
        subject.add_link_template('/child/{index}', 'child')
        href = subject.link('child').href
        href.to_s.should eq('/child/{index}')
      end

      it 'adds a LinkTemplate' do
        subject.add_link_template('/child/{index}', 'child')
        subject.link('child').should be_a(LinkTemplate)
      end

      it 'adds a link helper' do
        subject.add_link_template('/child/{index}', 'child')
        service.should_receive(:get).with('/child/23')
        subject.child(23)
      end

    end
  end
end
