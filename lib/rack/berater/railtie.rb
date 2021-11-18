require 'rails/railtie'

module Rack
  class Berater
    class Railtie < Rails::Railtie
      initializer 'rack.berater' do |app|
        if ::Berater.middleware.include?(::Berater::Middleware::LoadShedder)
          app.middleware.use Rack::Berater::RailsPrioritizer
        end

        app.middleware.use Rack::Berater
      end
    end
  end
end
