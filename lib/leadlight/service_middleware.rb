require 'multi_json'
require 'leadlight/blank'
require 'leadlight/hyperlinkable'
require 'leadlight/representation'

module Leadlight

  class ServiceMiddleware
    def initialize(app, options={})
      @app = app
      @service = options.fetch(:service)
    end

    def call(env)
      env[:leadlight_service] = @service
      env[:request_headers]['Accept'] = default_accept_types
      @app.call(env).on_complete do |env|
        env[:leadlight_representation] = represent(env)
      end
    end

    private

    def default_accept_types
      %w[
        application/json
        text/x-yaml
        application/xml
        application/xhtml+xml
        text/html
        text/plain
      ]
    end

    def represent(env)
      content_type = env[:response_headers]['Content-Type']
      representation = if (env[:body] || '').size > 0
        ::MultiJson.decode(env[:body])
      else
        Blank.new
      end
      representation.
        extend(Representation).
        initialize_representation(env[:leadlight_service], env[:url], env[:response]).
        extend(Hyperlinkable).
        apply_all_tints
    end
  end

end
