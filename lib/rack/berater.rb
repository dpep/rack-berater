require "berater"
require "rack"
require "rack/berater/version"
require "set"

module Rack
  class Berater
    autoload :Railtie, "rack/berater/railtie"

    ERROR_TYPES = Set.new([ ::Berater::Overloaded ])

    def initialize(app, options = {})
      @app = app
      @options = {
        headers: {},
        status_code: options.fetch(:status_code, 429),
      }

      # configure body
      @options[:body] = case options[:body]
        when true, nil
          Rack::Utils::HTTP_STATUS_CODES[@options[:status_code]]
        when false
          nil
        when String
          options[:body]
        else
          raise ArgumentError, "invalid :body option: #{options[:body]}"
        end

      # configure headers
      if @options[:body]
        @options[:headers][Rack::CONTENT_TYPE] = "text/plain"
      end
      @options[:headers].update(options.fetch(:headers, {}))
    end

    def call(env)
      @app.call(env)
    rescue *ERROR_TYPES => e
      [
        @options[:status_code],
        @options[:headers],
        [ @options[:body] ].compact,
      ]
    end
  end
end
