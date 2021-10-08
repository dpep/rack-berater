require "rails"
require "rack/berater/railtie"

RSpec.describe Rack::Berater::Railtie do
  subject { Rails.initialize! }

  before do
    Rails.application = Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  it "adds middleware automatically" do
    expect(subject.middleware).to include(Rack::Berater)
  end
end
