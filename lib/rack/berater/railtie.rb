require 'rails/railtie'

module Rack
  module Berater
    class Railtie < Rails::Railtie
      initializer "rack.berater.initializer" do |app|
        app.middleware.use Rack::Berater
      end
    end
  end
end
