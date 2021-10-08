require "rails/railtie"

module Rack
  class Berater
    class Railtie < Rails::Railtie
      initializer "rack.berater" do |app|
        app.middleware.use Rack::Berater
      end
    end
  end
end
