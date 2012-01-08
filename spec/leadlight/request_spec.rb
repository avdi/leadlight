require 'spec_helper_lite'
require 'leadlight/request'
require 'timeout'

module Leadlight
  describe Request do
    include Timeout


    # The Faraday connection API works like this:
    #
    # connection.run_request(:get, ...).on_complete do |env|
    #   ...
    # end
    #
    # TODO stick a facade over Faraday instead of stubbing stuff I
    # don't own
    class FakeFaradayResponse
      fattr(:completion_handlers) { Queue.new }
      attr_reader :env

      def initialize(env)
        @env = env
      end

      def on_complete(&block)
        completion_handlers << block
      end

      def run_completion_handlers(n=1)
        n.times do
          completion_handlers.pop.call(@env)
        end
      end
    end

    subject { Request.new(connection, url, http_method, params, body) }
    let(:connection) { stub(:connection, :run_request => faraday_response) }
    let(:url)        { stub(:url)        }
    let(:http_method){ :get              }
    let(:body)       { stub(:body)       }
    let(:params)     { {}                }
    let(:faraday_request) {stub(:faraday_request)}
    let(:on_complete_handlers) { [] }
    let(:faraday_response) { FakeFaradayResponse.new(faraday_env) }
    let(:faraday_env)      { {:leadlight_representation => representation} }
    let(:representation)   { stub(:representation) }

    def run_completion_handlers
      faraday_response.run_completion_handlers
    end

    def do_it_and_complete(&block)
      t = Thread.new do
        do_it(&block)
      end
      run_completion_handlers
      t.join.value
    end

    context "for GET" do
      let(:http_method) { :get }

      its(:http_method) { should eq(:get) }
    end


    context "for POST" do
      let(:http_method) { :post }

      its(:http_method) { should eq(:post) }
    end

    describe "#submit" do
      it "starts a request runnning" do
        connection.should_receive(:run_request).
          with(http_method, url, body, {}).
          and_return(faraday_response)
        subject.submit
      end

      it "triggers the on_prepare_request hook in the block passed to #run_request" do
        yielded         = :nothing
        faraday_request = stub
        connection.stub(:run_request).
          and_yield(faraday_request).
          and_return(faraday_response)
        subject.on_prepare_request do |request|
          yielded = request
        end
        subject.submit
        yielded.should equal(faraday_request)
      end

    end

    shared_examples_for "synchronous methods" do
      it "returns once the request has completed" do
        timeout(1) do
          trace = Queue.new
          thread = Thread.new do
            do_it
            trace << "wait finished"
          end
          trace << "completing request"
          faraday_response.run_completion_handlers
          thread.join
          trace << "request completed"
          trace.pop.should eq("completing request")
          trace.pop.should eq("wait finished")
          trace.pop.should eq("request completed")
        end
      end
    end

    describe "#wait" do
      context "before a submit" do
        it "doesn't return until after the submit" do
          timeout(1) do
            trace = Queue.new
            thread = Thread.new do
              subject.wait
              trace << "wait finished"
            end
            trace << "submit"
            subject.submit
            trace << "completing request"
            faraday_response.run_completion_handlers
            thread.join
            trace << "request completed"
            trace.pop.should eq("submit")
            trace.pop.should eq("completing request")
            trace.pop.should eq("wait finished")
            trace.pop.should eq("request completed")
          end
        end
      end

      context "after a submit" do
        before do
          subject.submit
        end

        def do_it
          subject.wait
        end

        it_should_behave_like "synchronous methods"

        it "returns self" do
          do_it_and_complete.should equal(subject)
        end
      end

    end

    describe "#submit_and_wait" do
      def do_it(&block)
        subject.submit_and_wait(&block)
      end

      it_should_behave_like "synchronous methods"

      it "returns self" do
        do_it_and_complete.should equal(subject)
      end

      it "yields the response representation" do
        yielded = :nothing
        do_it_and_complete do |rep|
          yielded = rep
        end
        yielded.should equal(representation)
      end
    end

    describe "#on_complete" do
      def submit_and_complete
        t = Thread.new do
          subject.submit
          subject.wait
        end
        run_completion_handlers
        t.join
      end

      it "queues hooks to be run on completion" do
        run_hooks = []
        subject.on_complete do |response|
          run_hooks << "hook 1"
        end
        subject.on_complete do |response|
          run_hooks << "hook 2"
        end
        submit_and_complete
        run_hooks.should eq(["hook 1", "hook 2"])
      end

      it "calls hooks with the faraday response" do
        Faraday::Response.should_receive(:new).with(faraday_env).
          and_return(faraday_response)
        yielded = :nothing
        subject.on_complete do |response|
          yielded = response
        end
        submit_and_complete
        yielded.should equal(faraday_response)
      end
    end
  end
end
