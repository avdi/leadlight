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

    describe '#initialize_representation' do
      it 'sets __service__, __location__, and __response__' do
        subject.initialize_representation(service, location, response)
        subject.__service__.should equal(service)
        subject.__location__.should equal(location)
        subject.__response__.should equal(response)
      end

      it 'returns self' do
        result = subject.initialize_representation(service, location, response)
        result.should equal(subject)
      end

    end
    describe '#apply_all_tints' do
      before do
        subject.initialize_representation(service, location, response)
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
