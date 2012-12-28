require 'spec_helper_lite'
require 'addressable/template'
require 'addressable/uri'
require 'leadlight/tint_helper'

module Leadlight
  describe TintHelper do
    subject{ TintHelper.new(object, tint) }
    let(:object) {
      stub(__location__: Addressable::URI.parse('/the/path'),
           __response__: response,
           __captures__: captures)
    }
    let(:response) {
      stub(:response,
           env:          env,
           status:       200)
    }
    let(:env) { {response_headers: headers} }
    let(:headers) {
      { 'Content-Type' => 'text/html; charset=UTF-8'}
    }
    let(:tint) { Module.new }
    let(:captures) { {} }

    it 'forwards unknown calls to the wrapped object' do
      object.should_receive(:foo).with('bar')
      subject.foo('bar')
    end

    describe '#match_path' do
      it 'allows execution to proceed on match' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_path('/the/path')
          baz
        end
      end

      it 'can match on a Regexp' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_path(/path/)
          baz
        end
      end

      it 'adds regex captures to representation captures' do
        subject.exec_tint do
          match_path(%r{/(?<x>\w+)/(?<y>\w+)})
        end
        captures.should eq('x' => 'the', 'y' => 'path')
      end

      it 'does not allow execution to proceed on no match' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match_path('/the/wrong/path')
          baz
        end
      end
    end

    describe '#match_template' do
      it 'allows execution to proceed on match' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_template('/{a}/{b}')
          baz
        end
      end

      it 'halts execution on no match' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match_template('/{a}/{b}/{c}')
          baz
        end
      end

      it 'adds mappings to representation captures' do
        subject.exec_tint do
          match_template('/{a}/{b}')
        end
        captures.should eq('a' => 'the', 'b' => 'path')
      end
    end

    describe '#match_content_type' do
      it 'allows execution to proceed on match' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_content_type('text/html')
          baz
        end
      end

      it 'can match on a regex' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_content_type(/text/)
          baz
        end
      end

      it 'does not allow execution to proceed on no match' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match_content_type('text/plain')
          baz
        end
      end
    end

    describe '#match_status' do
      it 'allows execution to proceed on match' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_status(200)
          baz
        end
      end

      it 'can match on a range' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_status(200..299)
          baz
        end
      end

      it 'does not allow execution to proceed on no match' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match_status(301)
          baz
        end
      end

      it 'accepts pattern shortcuts' do
        object.should_receive(:baz)
        subject.exec_tint do
          match_status(:any)
          baz
        end
      end
    end

    describe '#match' do
      let(:successful_matcher) {
        stub.tap do |matcher|
          matcher.should_receive(:===).with(object).and_return(true)
        end
      }
      let(:failing_matcher) {
        stub.tap do |matcher|
          matcher.should_receive(:===).with(object).and_return(false)
        end
      }

      it 'allows execution to proceed on true return' do
        object.should_receive(:baz)
        subject.exec_tint do
          match{ (2 + 2) == 4 }
          baz
        end
      end

      it 'can match a given param against the representation' do
        matcher = successful_matcher
        object.should_receive(:baz)
        subject.exec_tint do
          match matcher
          baz
        end
      end

      it 'can match several params against the representation' do
        matchers = [ failing_matcher, successful_matcher ]
        object.should_receive(:baz)
        subject.exec_tint do
          match *matchers
          baz
        end
      end

      it 'can match using params and a block' do
        param_matcher = failing_matcher
        block_matcher = proc { (2 + 2) == 4 }
        object.should_receive(:baz)
        subject.exec_tint do
          match param_matcher, &block_matcher
          baz
        end
      end

      it 'does not allow execution to proceed on false return' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match{ (2 + 2) == 5 }
          baz
        end
      end
    end

    describe '#exec_tint' do
      it 'returns self' do
        subject.exec_tint{}.should equal(subject)
      end
    end

    describe '#add_header' do
      it 'adds a header' do
        subject.add_header('MyHeader', 'Hello world')
        headers['MyHeader'].should eq('Hello world')
      end
    end

    describe '#extend' do
      context 'given a module' do
        let(:mod) { Module.new }

        it 'extends the object with the given module' do
          subject.extend(mod)
          object.should be_a(mod)
        end
      end

      context 'given a block' do
        it 'extends the tint module with the given definitions' do
          subject.extend do
            def magic_word
              'xyzzy'
            end
          end
          object.magic_word.should eq('xyzzy')
        end
      end
    end

  end
end
