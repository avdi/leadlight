require 'spec_helper_lite'
require 'leadlight/representation'

module Leadlight
  describe Representation do
    module TintA; end
    module TintB; end

    subject { object }
    let(:object)  { Object.new.extend(Representation) }
    let(:service) { stub(:service, tints: [TintA, TintB]) }
    let(:location) { stub(:location) }
    let(:response) { stub(:response) }
    let(:params)   { stub(:params)   }
    let(:link)     { stub(:link)     }
    let(:request)  { stub(:request, params: params, link: link)  }

    it 'has a __service__ accessor' do
      subject.__service__ = service
      subject.__service__.should equal(service)
    end

    it 'has a __location__ accessor' do
      subject.__location__ = location
      subject.__location__.should equal(location)
    end

    it 'has a __response__ accessor' do
      subject.__response__ = response
      subject.__response__.should equal(response)
    end

    it 'has a __request__ accessor' do
      subject.__request__ = request
      subject.__request__.should equal(request)
    end

    it 'has a __link__ accessor' do
      subject.__request__ = request
      subject.__link__.should equal(link)
    end

    it 'has a __params__ accessor' do
      subject.__request__ = request
      subject.__params__.should equal(params)
    end

    describe '#initialize_representation' do
      it 'sets __service__, __location__, __response__, and __request__' do
        subject.initialize_representation(service, location, response, request)
        subject.__service__.should equal(service)
        subject.__location__.should equal(location)
        subject.__response__.should equal(response)
        subject.__request__.should equal(request)
      end

      it 'returns self' do
        result = subject.initialize_representation(service,
                                                   location,
                                                   response,
                                                   request)
        result.should equal(subject)
      end

    end
    describe '#apply_all_tints' do
      before do
        subject.initialize_representation(service, location, response, params)
      end

      it 'extends object with tints from service' do
        subject.apply_all_tints
        subject.should be_a(TintA)
        subject.should be_a(TintB)
      end

      it 'applies tints' do
        object.should_receive(:__apply_tint__)
        subject.apply_all_tints
      end
    end

  end
end
