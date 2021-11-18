require 'rack'

module Rack
  class Berater
    class Prioritizer
      ENV_KEY = 'berater_priority'
      HEADER = 'X-Berater-Priority'

      def initialize(app, options = {})
        @app = app
        @header = options[:header] || HEADER
      end

      def call(env)
        priority = env[@header] || env["HTTP_#{@header.upcase.tr('-', '_')}"]

        if priority
          set_priority(priority)
          return @app.call(env)
        end

        cache_key = cache_key_for(env)
        cached_priority = cache_get(cache_key)

        if cached_priority
          set_priority(cached_priority)
        end

        @app.call(env).tap do |status, headers, body|
          app_priority = headers.delete(@header) if headers

          if app_priority && app_priority != cached_priority
            # update cache for next time
            cache_set(cache_key, app_priority)
          end
        end
      ensure
        Thread.current[ENV_KEY] = nil
      end

      def self.current_priority
        Thread.current[ENV_KEY]
      end

      protected

      def set_priority(priority)
        Thread.current[ENV_KEY] = priority
      end

      @@cache_prefix = 'Berater:Rack:Prioritizer'
      def cache_key_for(env)
        req = Rack::Request.new(env)

        req_method = env[Rack::REQUEST_METHOD].downcase
        path = ''

        if defined?(Rails) && Rails.respond_to?(:application)
          res = Rails.application.routes.recognize_path(env[Rack::PATH_INFO])
          path = res.values_at(:controller, :action).compact.join('#')
        end

        if path.empty?
          path = env['PATH_INFO'].gsub(%r{/[0-9]+(/|$)}, '/x\1')
        end

        [
          @@cache_prefix,
          req_method,
          path,
        ].join(':')
      end

      @@cache = {}

      def cache_get(key)
        synchronize { @@cache[key] }
      end

      def cache_set(key, priority)
        synchronize { @@cache[key] = priority }
      end

      @@lock = Thread::Mutex.new
      def synchronize(&block)
        @@lock.synchronize(&block)
      end
    end
  end
end
