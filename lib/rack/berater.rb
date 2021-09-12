require "rack/berater/version"

module Rack
  module Berater
    autoload :Handler, "rack/berater/handler"
    # autoload :Limiter, "rack/berater/limiter"
    autoload :Railtie, "rack/berater/railtie"
  end
end
