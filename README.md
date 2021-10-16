Rack::Berater
======
Limit incoming Rack requests with [Berater](https://github.com/dpep/berater_rb).



## Basic Usage

Transform limit errors into HTTP status code 429s
```ruby
require "rack/berater/railtie"
```


## Customized Response

```ruby
Rack::Berater, options
```
* `options`
  * `status_code` - which HTTP status code to return when a limit error occurs
  * `body` - what message to return when a limit error occurs
  * `headers` - hash of which headers to return when a limit error occurs

```ruby
require "rack-berater"

Rails.application.middleware.use(Rack::Berater, status_code: 503)
```


## Custom Error Types
Register exceptions to be handled by Rack::Berater

```ruby
Rack::Berater::ERRORS << NoMemoryError
```

----
## Contributing

Yes please  :)

1. Fork it
1. Create your feature branch (`git checkout -b my-feature`)
1. Ensure the tests pass (`bundle exec rspec`)
1. Commit your changes (`git commit -am 'awesome new feature'`)
1. Push your branch (`git push origin my-feature`)
1. Create a Pull Request


----
![Gem](https://img.shields.io/gem/dt/rack-berater?style=plastic)
[![codecov](https://codecov.io/gh/dpep/rack-berater/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/rack-berater)
