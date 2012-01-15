require 'spec_helper_lite'
require 'leadlight/tint'

module Leadlight
  describe Tint do    
    subject { target.extend(Tint.new(:test_tint, options, &definition)) }
    let(:definition) {
      ->(*args) do
        self.tint_applied!
      end
    }
    let(:target) { Target.new }
    let(:status) { 200 }
    let(:response) { stub(:status => status) }
    let(:options) { {} }

    class Target
      def __apply_tint__
      end
    end

    def apply
      subject.__apply_tint__
    end

    before do
      target.stub(:__response__ => response)
    end

    context "with a successful status" do
      it "is applied" do
        target.should_receive(:tint_applied!)
        apply
      end
    end

    context "with an unsuccessful status" do
      let(:status) { 401 }

      it "is not applied" do
        target.should_not_receive(:tint_applied!)
        apply
      end
    end

    context "with a custom status guard" do
      before do
        options[:status] = 401
      end

      context "with a non-matching status" do
        it "is not applied" do
          target.should_not_receive(:tint_applied!)
          apply
        end
      end

      context "with an matching status" do
        let(:status) { 401 }

        it "is applied" do
          target.should_receive(:tint_applied!)
          apply
        end
      end

    end
  end
end
