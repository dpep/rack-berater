require 'rack/berater'
require 'rspec/core'

RSpec.configure do |config|
  config.after do
    Thread.current[Rack::Berater::Prioritizer::ENV_KEY] = nil

    Rack::Berater::Prioritizer.class_variable_get(:@@cache).clear
  end
end
