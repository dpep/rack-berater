module Rack
  class Berater
    class RailsPrioritizer < Prioritizer
      def cache_key_for(env)
        Rails.application.routes.recognize_path(
          env[Rack::PATH_INFO],
          method: env[Rack::REQUEST_METHOD],
        ).values_at(:controller, :action).compact.join('#')
      rescue ActionController::RoutingError, NoMethodError
        super
      end
    end
  end
end
