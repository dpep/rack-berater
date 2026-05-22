require_relative 'lib/rack/berater/version'

Gem::Specification.new do |s|
  s.name        = 'rack-berater'
  s.version     = Rack::Berater::VERSION
  s.authors     = ['Daniel Pepper']
  s.summary     = 'Rack::Berater'
  s.description = 'limit incoming requests'
  s.homepage    = 'https://github.com/dpep/rack-berater'
  s.license     = 'MIT'

  s.files       = Dir.glob('lib/**/*')
  s.test_files  = Dir.glob('spec/**/*_spec.rb')

  s.add_dependency 'berater'
  s.add_dependency 'rack'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'codecov'
  s.add_development_dependency 'graphql'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rails', '< 7'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'simplecov'
end
