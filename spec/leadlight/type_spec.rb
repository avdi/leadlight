require 'spec_helper_lite'
require 'leadlight/type'

module Leadlight
  describe Type do
    let(:service) { stub(:service) }
    let(:name)    { "test_type" }
    let(:type)    { Type.new(name, service, &body) }
    let(:body)    { Proc.new{} }
    let(:instance){ stub(:instance) }
    let(:object)  { instance.extend(type) }
    let(:encoder) { stub(:encoder) }
    
    subject { type }

    its(:name) { should eq(name) }
    its(:service) { should equal(service) }
    its(:inspect) { should eq("#<Leadlight::Type:#{name}>") }
    its(:to_s)    { should eq("Type(#{name})") }

    describe '#build' do
      let(:body) {  
        my_builder = stub_builder
        proc do |*args|
          builder &my_builder
        end
      }
      let(:stub_builder) { proc{|*args| instance} }
      it 'uses the specified builder block' do
        type.build.should eq(instance)
      end

      it 'passes params to the builder' do
        stub_builder.should_receive(:call).with(1,2,3)
        type.build(1,2,3)
      end

      it 'yields the built object' do
        yielded = :not_set
        type.build do |obj|
          yielded = obj
        end
        yielded.should equal(instance)
      end

      it 'includes itself into the built object' do
        type.build.should be_a(type)
      end
      
      context 'with no builder specified' do
        let(:body) { proc{} }
        it 'defaults to Object.new' do
          type.build.class.should == Object
        end
      end
    end

    describe 'when included' do
      subject { object }
      it 'adds a __type__ to the extended object, referencing itself' do
        subject.__type__.should equal(type)
      end
    end

    describe '#enctype' do
      context 'when unspecified' do
        its(:enctype) { should eq('application/json') }

        it 'is used when encoding' do
          body        = stub
          entity_body = stub
          options     = {encoder: encoder}
          encoder.should_receive(:encode).
            with('application/json', body, options).
            and_return(entity_body)
          type.encode(body, options).should equal(entity_body)
        end
      end

      context 'when explicitly specified' do
        let(:body) { proc{ enctype 'text/plain' } }

        it 'is changed' do
          type.enctype.should eq('text/plain')
        end

        it 'is used when encoding' do
          body        = stub
          entity_body = stub
          options     = {encoder: encoder}
          encoder.should_receive(:encode).
            with('text/plain', body, options).
            and_return(entity_body)
          type.encode(body, options).should equal(entity_body)
        end
      end
    end

    describe 'link_to_create' do
      let(:body) { 
        the_link = link
        proc {
          link_to_create(the_link)
        }
      }
      let(:link) { '/foo/{x}/bar' }

      it 'is saved' do
        type.link_to_create.should eq(link)
      end

      it 'adds a link to the representation' do
        instance.should_receive(:add_link).with(link, 'create', "Create a new #{name}")
        object
      end

    end

    describe '#tint' do
      subject { type.tint }

      it { should be_a(Tint) }
      its(:name) { should eq("type:#{name}") }
    end

    describe '#encode' do
      it 'defaults to using the representation service as encoder' do
        representation = stub(__service__: service)
        entity = stub
        service.should_receive(:encode).
          with('application/json', representation, {}).
          and_return(entity)
        type.encode(representation).should equal(entity)
      end
    end
  end
end
