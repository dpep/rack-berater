require "berater"
require "rack"
require "rack/berater/version"

module Rack
  class Berater
    autoload :Railtie, "rack/berater/railtie"

    def initialize(app, options = {})
      @app = app
      @options = {
        status_code: options.fetch(:status_code, 429),
        headers: {
          Rack::CONTENT_TYPE => "text/plain",
        }.update(options.fetch(:headers, {})),
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

      headers = body ? @options[:headers] : {}

      [
        code,
        headers,
        [ body ].compact,
      ]
    end
  end
end
