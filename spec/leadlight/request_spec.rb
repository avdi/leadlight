require 'spec_helper_lite'
require 'leadlight/request'
require 'timeout'

module Leadlight
  describe Request do
    include Timeout

    before :all do
      @old_abort_on_exception = Thread.abort_on_exception
      Thread.abort_on_exception = true
    end

    after :all do
      Thread.abort_on_exception = @old_abort_on_exception
    end

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
          handler = completion_handlers.pop
          handler.call(@env)
        end
      end

      def success?
        true
      end
    end

    subject { Request.new(service, connection, url, http_method, body, options) }
    let(:service)    { stub(:service, :type_map => type_map) }
    let(:type_map)   { stub(:type_map).as_null_object }
    let(:connection) { stub(:connection, :run_request => faraday_response) }
    let(:url)        { stub(:url, :to_s => "STRINGIFIED_URL") }
    let(:http_method){ :get              }
    let(:body)       { stub(:body)       }
    let(:faraday_request) {stub(:faraday_request, options: {}, params: request_params)}
    let(:on_complete_handlers) { [] }
    let(:faraday_env)      { {request: faraday_request} }
    let(:representation)   { stub(:representation) }
    let(:faraday_response) { FakeFaradayResponse.new(faraday_env) }
    let(:link)             { stub(:link, params: link_params) }
    let(:link_params)      { { a: "123", b: "456" } }
    let(:request_params)   { { b: "789", c: "321" } }
    let(:options)          { { link: link } }

    def run_completion_handlers
      faraday_env[:status]   ||= 200
      faraday_env[:response] ||= faraday_response
      faraday_env[:leadlight_representation] ||= representation
      faraday_response.run_completion_handlers
    end

    def do_it_and_complete(&block)
      t = Thread.new do
        do_it(&block)
      end
      run_completion_handlers
      t.join(1).value
    end

    before do
      subject.stub!(:represent => representation)
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
      let(:request_params)  { stub }
      let(:faraday_request) {
        stub(options: {}, headers: {}, params: request_params)
      }

      before do
        connection.stub(:run_request).
          and_yield(faraday_request).
          and_return(stub.as_null_object)
      end

      it "starts a request runnning" do
        connection.should_receive(:run_request).
          with(http_method, "STRINGIFIED_URL", anything, {}).
          and_return(faraday_response)
        subject.submit
      end

      it "triggers the on_prepare_request hook in the block passed to #run_request" do
        yielded = :nothing
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
          run_completion_handlers
          thread.join(1)
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
            run_completion_handlers
            thread.join(1)
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
        t.join(1)
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
        yielded = :nothing
        subject.on_complete do |response|
          yielded = response
        end
        submit_and_complete
        yielded.should equal(faraday_response)
      end
    end

    describe "#on_error" do
      def submit_and_complete
        t = Thread.new do
          subject.submit
          subject.wait
        end
        run_completion_handlers
        t.join(1)
        subject
      end

      it "yields to the block when response is an error" do
        called = :not_set
        block = proc{ called = true }
        faraday_response.should_receive(:success?).and_return(false)
        submit_and_complete.on_error(&block)
        called.should be_true
      end

      it "does not yield to the block when response is sucess" do
        called = :not_set
        block = proc { called = true }
        faraday_response.should_receive(:success?).and_return(true)
        submit_and_complete.on_error(&block)
        called.should eq(:not_set)
      end

      it "passes the representation to the handler" do
        passed = :not_set
        block = ->(arg) { passed = arg }
        faraday_response.should_receive(:success?).and_return(false)
        submit_and_complete.on_error(&block)
        passed.should equal(representation)
      end
    end

    describe "#raise_on_error" do
      def submit_and_complete
        t = Thread.new do
          subject.submit
          subject.wait
        end
        run_completion_handlers
        t.join(1)
        subject
      end

      it "raises an error when the response is a client error" do
        faraday_response.should_receive(:success?).and_return(false)
        subject.should_receive(:raise).with(representation)
        submit_and_complete.raise_on_error
      end

      it "raises after completion when called before completion" do
        faraday_response.should_receive(:success?).and_return(false)
        subject.raise_on_error
        subject.should_receive(:raise).with(representation)
        submit_and_complete
      end

    end

    describe "#link" do
      it "defaults to a null link with the URL passed in" do
        subject = Request.new(service, connection, url, http_method, body)
        subject.link.should eq(NullLink.new(url))
      end

      it 'is taken from options supplied to constructor' do
        link = double
        subject = Request.new(service, connection, url, http_method, body, link: link)
        subject.link.should be(link)
      end
    end

    describe "#params" do
      context "(after completion)" do
        def do_it(&block)
          subject.submit_and_wait(&block)
        end

        before do
          do_it_and_complete
        end

        it 'merges request params and link params' do
          subject.params.should eq(a: "123", b: "789", c: "321")
        end
      end
    end

  end
end
