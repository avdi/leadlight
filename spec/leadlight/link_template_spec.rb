require 'spec_helper_lite'
require 'leadlight/link_template'
require 'leadlight/type_map'

module Leadlight
  describe LinkTemplate do

    include LinkMatchers

    # TODO: This setup is loony. Refactor.
    subject { LinkTemplate.new(service, href, rel, title, options) }
    let(:service) { stub(:service, type_map: TypeMap.new) }
    let(:request) { stub(:request)               }
    let(:result)  { stub(:result)                }
    let(:href)    { '/TEST_PATH/{n}/{m}/'   }
    let(:rel)     { 'TEST_REL'     }
    let(:title)   { 'TEST_TITLE'   }
    let(:options) { {}             }
    let(:mapping) { {'n' => 'N_VALUE', 'm' => 'M_VALUE'} }
    let(:values)  { mapping.values }

    before do
      request.stub(raise_on_error: request)
      service.stub(:get_representation!).and_yield(result).and_return(request)
    end

    it { should(expand_to('/TEST_PATH/N/M/?foo=bar').
                with_params('n' => 'N', 'm' => 'M').
                given(:n => "N", :m => "M", :foo => 'bar'))}

    it { should(expand_to('/TEST_PATH/N/M/?foo=bar&x=42').
                given(:n => "N", :m => "M", :foo => 'bar', "x" => 42))}

    it { should(expand_to('/TEST_PATH/N/M/?foo[0]=123&foo[1]=456').
                given(:n => "N", :m => "M", :foo => [123,456])) }

    describe '#follow' do
      it 'calls service.get with the expanded href' do
        service.should_receive(:get_representation!).
          with(u('/TEST_PATH/23/42/'))
        subject.follow(23,42)
      end

      it 'can accept a hash for template parameters' do
        service.should_receive(:get_representation!).
          with(u('/TEST_PATH/AA/BB/'))
        subject.follow(:n => 'AA', 'm' => 'BB')
      end


      it 'tacks unrecognized on as query params' do
        service.should_receive(:get_representation!).
          with(u('/TEST_PATH/AA/BB/?other=XX'))
        subject.follow(:n => 'AA', 'm' => 'BB', :other => 'XX')
      end

      it 'returns the result of the get' do
        subject.follow(23,42).should equal(result)
      end
    end
  end
end
