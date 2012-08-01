module Faraday
  class Connection
    def initialize(url = nil, options = {})
      if url.is_a?(Hash)
        options = url
        url     = options[:url]
      end
      @headers = Utils::Headers.new
      @params  = Utils::ParamsHash.new
      @options = options[:request] || {}
      @ssl     = options[:ssl]     || {}
      adapter  = options[:adapter]

      @parallel_manager = nil
      @default_parallel_manager = options[:parallel_manager]

      @builder = options[:builder] || begin
        # pass an empty block to Builder so it doesn't assume default middleware
        block = block_given?? Proc.new {|b| } : nil
        Builder.new(&block)
      end

      self.url_prefix = url || 'http:/'

      @params.update options[:params]   if options[:params]
      @headers.update options[:headers] if options[:headers]

      @proxy = nil
      proxy(options.fetch(:proxy) { ENV['http_proxy'] })

      yield self if block_given?

      if adapter
        self.adapter = adapter
      end
    end

    def_delegators :builder, :adapter=
  end
end
