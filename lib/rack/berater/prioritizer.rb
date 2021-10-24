require "rack"

module Rack
  class Berater
    def initialize(app, options = {})
      @app = app
      @header = options[:header] || "X-Berater-Priority"
    end

    @cache = {}
    def call(env)
      priority = env[@options[:priority_header]]
      cache_key = "method:path:controller:params"

      if priority.nil?
        env[@options[:priority_header]] = @priority_cache[cache_key]
      end

      @app.call(env).tap do |status, headers, body|
        res_priority = if options[:strip_priority]
          headers.delete(@options[:priority_header])
        else
          headers[@options[:priority_header]]
        end

        # update cache for next time
        if priority.nil? && res_priority
          @priority_cache[cache_key] = res_priority
        end
      end
    end
  end
end
