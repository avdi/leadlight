require 'spec_helper_lite'
require 'leadlight/tint_helper'

module Leadlight
  describe TintHelper do
    subject{ TintHelper.new(object, tint) }
    let(:object) {
      stub(__location__: stub(path: '/the/path'),
           __response__: response)
    }
    let(:response) {
      stub(:response,
           env:          env)
    }
    let(:env) { {response_headers: headers} }
    let(:headers) {
      { 'Content-Type' => 'text/html; charset=UTF-8'}
    }
    let(:tint) { Module.new }

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

      it 'does not allow execution to proceed on no match' do
        object.should_not_receive(:baz)
        subject.exec_tint do
          match_path('/the/wrong/path')
          baz
        end
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

    describe '#match' do
      it 'allows execution to proceed on true return' do
        object.should_receive(:baz)
        subject.exec_tint do
          match{ (2 + 2) == 4 }
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
