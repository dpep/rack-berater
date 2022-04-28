require 'rspec/rails'

describe Rack::Berater do
  before do
    class OkController < ActionController::Base
      around_action :limit

      def limit(&block)
        Berater(:key, 1) { yield }
      end

      def index
        head :ok
      end
    end

    Rails.application = Class.new(Rails::Application) do
      config.eager_load = false
      config.hosts.clear # disable hostname filtering
      # config.logger = ActiveSupport::Logger.new($stdout)
    end
    Rails.application.middleware.use described_class
    Rails.initialize!

    Rails.application.routes.draw do
      get '/' => 'ok#index'
    end
  end

  let(:app) { Rails.application }

  it { expect(get('/')).to be_ok }

  context 'when past limits' do
    before { Berater.test_mode = :fail }

    it { expect(get('/').status).to be 429 }
  end
end
