require 'berater'
require 'rack'
require 'rack/berater/version'
require 'set'

module Rack
  class Berater
    autoload :Prioritizer, 'rack/berater/prioritizer'
    autoload :RailsPrioritizer, 'rack/berater/rails_prioritizer'
    autoload :Railtie, 'rack/berater/railtie'

    ERRORS = Set[ ::Berater::Overloaded ]

    def initialize(app, options = {})
      @app = app
      @enabled = options[:enabled?]
      @limiter = options[:limiter]
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
          raise ArgumentError, 'invalid :body option: #{options[:body]}'
        end

      # configure headers
      if @options[:body]
        @options[:headers][Rack::CONTENT_TYPE] = 'text/plain'
      end
      @options[:headers].update(options.fetch(:headers, {}))
    end

    def call(env)
      if enabled?(env)
        limit(env) { @app.call(env) }
      else
        @app.call(env)
      end
    rescue *ERRORS => e
      [
        @options[:status_code],
        @options[:headers],
        [ @options[:body] ].compact,
      ]
    end

    private

    def enabled?(env)
      return false unless @limiter
      @enabled.nil? ? true : @enabled.call(env)
    end

    def limit(env, &block)
      limiter = @limiter.respond_to?(:call) ? @limiter.call(env) : @limiter
      limiter.limit(&block)
    end
  end
end
