module Rack
  module Berater
    class Handler
      def initialize(app, options = {})
        @app = app
        @options = {
          status_code: options.fetch(:status_code, 429),
          body: options.fetch(:body, true),
        }
      end

      def call(env)
        @app.call(env)
      rescue ::Berater::Overloaded => e
        code = @options[:status_code]
        body = case @options[:body]
          when true
            Rack::Utils::HTTP_STATUS_CODES[code]
          when nil, false
            nil
          when String
            @options[:body]
          when Proc
            @options[:body].call(env, e)
          else
            raise ArgumentError, "invalid :body option: #{@options[:body]}"
          end

        [
          code,
          {},
          [ body ].compact,
        ]
      end
    end
  end
end
