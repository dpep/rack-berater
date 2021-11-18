require 'rspec/rails'

describe Rack::Berater::RailsPrioritizer do
  before do
    class EchoController < ActionController::Base
      def index
        render plain: Rack::Berater::Prioritizer.current_priority
      end

      def six
        response.set_header(Rack::Berater::Prioritizer::HEADER, '6')
        index
      end

      def nine
        response.set_header(Rack::Berater::Prioritizer::HEADER, '9')
        index
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
      get '/' => 'echo#index'
      get '/six' => 'echo#six'
      post '/nine' => 'echo#nine'
      get '/redirect' => redirect('/')
    end
  end

  let(:app) { Rails.application }
  let(:middleware) { described_class.new(app) }

  after do
    cache.clear
    Thread.current[described_class::ENV_KEY] = nil
    Rails.application = nil
  end

  let(:cache) { described_class.class_variable_get(:@@cache) }

  describe '#cache_key_for' do
    subject { described_class.new(app).method(:cache_key_for) }

    it 'uses the controller and action name' do
      expect(
        subject.call(Rack::MockRequest.env_for('/'))
      ).to match /echo#index/

      expect(
        subject.call(Rack::MockRequest.env_for('/six'))
      ).to match /echo#six/

      expect(
        subject.call(Rack::MockRequest.env_for('/nine', method: 'POST'))
      ).to match /echo#nine/
    end

    it 'falls back to Rack style names' do
      expect(
        subject.call(Rack::MockRequest.env_for('/nine'))
      ).to match %r{get:/nine}
    end

    it 'works with redirects' do
      expect(
        subject.call(Rack::MockRequest.env_for('/redirect'))
      ).to match %r{get:/redirect}
    end
  end

  context 'when a priority header is sent' do
    before { header described_class::HEADER, priority }

    let(:priority) { '6' }

    it 'sets the priority' do
      expect(get('/six').body).to eq priority
    end
  end

  context 'when the app returns a priority' do
    it 'does not know the first time the controller is called' do
      expect(get('/six').body).to be_empty
      expect(post('/nine').body).to be_empty
    end

    it 'caches the repsonses for the second time' do
      expect(get('/six').body).to be_empty
      expect(post('/nine').body).to be_empty

      expect(get('/six').body).to eq '6'
      expect(post('/nine').body).to eq '9'
    end
  end
end
