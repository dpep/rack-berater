require 'graphql'
require 'rspec/rails'

class UserType < GraphQL::Schema::Object
  field :name, String, null: false
end

class QueryType < GraphQL::Schema::Object
  field :me, UserType

  def me
    { name: 'me' }
  end

  field :user, UserType do
    argument :id, ID
  end

  def user(id:)
    { name: "user_#{id}" }
  end
end

class Schema < GraphQL::Schema
  query QueryType
end

class GraphqlController < ActionController::Base
  def execute
    render json: Schema.execute(
      params[:query],
      variables: params[:variables],
      operation_name: params[:operationName]
    )
  end
end

describe Rack::Berater::GraphqlPrioritizer do
  before do
    Rails.application = Class.new(Rails::Application) do
      config.eager_load = false
      config.hosts.clear # disable hostname filtering
      config.logger = ActiveSupport::Logger.new($stdout)
    end
    Rails.application.middleware.use described_class
    Rails.initialize!

    Rails.application.routes.draw do
      post '/graphql', to: 'graphql#execute'
    end
  end

  let(:app) { Rails.application }
  let(:middleware) { described_class.new(app) }
  let(:query) { 'query Me { me { name } }'}

  after do
    Rails.application = nil
  end

  describe '#cache_key_for' do
    subject { described_class.new(app).method(:cache_key_for) }

    it 'uses the implicit graphql operation name' do
      expect(
        subject.call(Rack::MockRequest.env_for(
          '/graphql',
          params: {
            query: query,
          },
        ))
      ).to match /graphql:Me/
    end

    it 'uses the explicit graphql operation name param' do
      expect(
        subject.call(Rack::MockRequest.env_for(
          '/graphql',
          params: {
            query: query,
            operationName: 'What',
          },
        ))
      ).to match /graphql:What/
    end

    it 'works when operation name is missing' do
      expect(
        subject.call(Rack::MockRequest.env_for('/graphql'))
      ).to match /graphql/
    end

    it 'works when query is invalid' do
      expect(
        subject.call(Rack::MockRequest.env_for(
          '/graphql',
          params: {
            query: 'abc!!!',
          },
        ))
      ).to match /graphql/
    end

    it 'falls back to Rack style names' do
      expect(
        subject.call(Rack::MockRequest.env_for('/foo'))
      ).to match %r{GET:/foo}
    end
  end
end
