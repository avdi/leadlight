require 'spec_helper_lite'
require 'leadlight/type_map'

module Leadlight
  describe TypeMap do
    subject { TypeMap.new(codec: codec) }
    let(:codec) { stub(:codec) }
    let(:options) { {foo: 23} }
    let(:native_object) { stub(:native_object) }
    let(:body) { stub(:body, size: 2) }

    matcher :encode do |object|
      define_method :expected_options do
        @expected_options ||= anything
      end

      match{ |typemap|
        result = stub(:encode_result)
        @expected_type.should_receive(:encode).with(object, expected_options).
          and_return(result)
        typemap.to_entity_body(object).should equal(result)
      }

      chain :using do |expected_type|
        @expected_type = expected_type
      end

      chain :with_options do |expected_options|
        @expected_options = expected_options
      end
    end

    matcher :decode do |enctype|
      define_method :expected_options do
        @expected_options ||= anything
      end

      match{ |typemap|
        result = stub(:decode_result)
        @expected_type.should_receive(:decode).with(enctype, body, expected_options).
          and_return(result)
        typemap.to_native(enctype, body, options).should equal(result)
      }

      chain :using do |expected_type|
        @expected_type = expected_type
      end

      chain :with_options do |expected_options|
        @expected_options = expected_options
      end
    end

    describe "defaults" do
      it "encodes arbitrary objects to JSON" do
        codec.should_receive(:encode).
          with("application/json", native_object, options).
          and_return(body)
        result = subject.to_entity_body(native_object, options)
        result.content_type.should eq("application/json")
        result.body.should equal(body)
      end

      it "permits encode type to be overridden" do
        codec.should_receive(:encode).
          with("application/xml", native_object, {}).
          and_return(body)
        result = subject.to_entity_body(native_object, {content_type: 'application/xml'})
        result.content_type.should eq("application/xml")
        result.body.should equal(body)
      end

      it "decodes entity bodies using the codec" do
        codec.should_receive(:decode).
          with("application/foobaz", body, options).
          and_return(native_object)
        subject.to_native("application/foobaz", body, options)
      end

      it "decodes empty entity bodies as a Blank object" do
        subject.to_native("application/json", "", options).should be_a(Blank)
      end

      it "handles missing content type" do
        subject.to_native(nil, "", options).should be_a(Blank)
      end

    end

    describe "with some types defined" do
      let(:numeric_type) { stub(:numeric_type) }
      let(:custom_json_type) { stub(:custom_json_type) }

      before do
        subject.add "application/vnd.numeric", [Integer, Float], numeric_type
        subject.add ["application/json", /\+json/], Hash, custom_json_type
      end      

      it "encodes unmatched objects to JSON" do
        codec.should_receive(:encode).
          with("application/json", native_object, options).
          and_return(body)
        subject.to_entity_body(native_object, options)
      end

      it "decodes unmatched content types entity bodies using the codec" do
        codec.should_receive(:decode).
          with("application/foobaz", body, options).
          and_return(native_object)
        subject.to_native("application/foobaz", body,options)
      end

      it { should encode(123).using(numeric_type) }
      it { should encode(12.5).using(numeric_type) }
      it { should decode("application/vnd.numeric").using(numeric_type) }
      it { should encode({}).using(custom_json_type) }
      it { should decode("application/json").using(custom_json_type) }
      it { should decode("application/xyzzy+json").using(custom_json_type) }
    end
  end
end
