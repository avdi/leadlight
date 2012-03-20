require 'spec_helper_lite'
require 'leadlight/hyperlinkable'

module Leadlight
  describe Hyperlinkable do
    subject { representation.extend(Hyperlinkable) }
    let(:representation) { Object.new }
    let(:response) { stub(:response, env: env) }
    let(:response_url) { Addressable::URI.parse('/foo') }
    let(:request) { stub(:request) }
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
      representation.stub(__response__: response,
                          __service__: service,
                          __location__: '/foo')
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
      it 'swells the links collection' do
        expect { subject.add_link('/foo') }.to change{ subject.links.size }.by(1)
      end

      it 'expands links' do
        subject.add_link('/parent', 'parent')
        subject.link('parent').href.to_s.should eq('/parent')
      end

      it 'adds a Link' do
        subject.add_link('/parent', 'parent')
        subject.link('parent').should be_a(Link)
      end

      it 'adds a link helper' do
        subject.add_link('/parent', 'parent')
        service.should_receive(:get_representation!).
          with(Addressable::URI.parse('/parent')).
          and_return(request)
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
        service.should_receive(:get_representation!).
          with(u('/child/23'))
        subject.child(23)
      end

    end

    describe '#add_link_set' do
      before do
        subject.add_link_set('bourbon') do
          [
           {href: 'http://example.com/blantons',  title: 'Blantons'},
           {href: 'http://example.com/bookers',   title: 'Bookers'},
           {href: 'http://example.com/knobcreek', title: 'Knob Creek', aliases: ['KC']},
          ]
        end
      end

      it 'adds links for each member of the set' do
        links = subject.links('bourbon').map(&:href).map(&:to_s)
        links.should include('http://example.com/blantons')
        links.should include('http://example.com/bookers')
        links.should include('http://example.com/knobcreek')
      end

      it 'establishes a link helper that finds by title' do
        result_stubs = [stub, stub, stub]
        service.should_receive(:get_representation!).and_yield(result_stubs[0])
        service.should_receive(:get_representation!).and_yield(result_stubs[1])
        service.should_receive(:get_representation!).and_yield(result_stubs[2])
        subject.bourbon('Blantons').should equal(result_stubs[0])
        subject.bourbon('Bookers').should equal(result_stubs[1])
        subject.bourbon('Knob Creek').should equal(result_stubs[2])
      end

      it 'sets up the link helper to handle aliases' do
        result = stub
        service.should_receive(:get_representation!).and_yield(result)
        subject.bourbon('KC').should equal(result)
      end
    end
  end
end
