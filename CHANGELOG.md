###  v0.5.0  (2026-11-09)
- Add `Rack::Berater::GraphqlPrioritizer`, which keys the priority cache on the GraphQL operation name for `/graphql` requests.
- Requires Ruby 3.3 or newer. Supports Rack 3 and Rails 7+.
- Fix `Prioritizer` ignoring the priority header when a Rack 3 app returns it lowercase, as the Rack 3 spec requires: it was neither cached nor removed from the response.
- `RailsPrioritizer` falls back to path-based cache keys when routes are unavailable, rather than raising.
- Subclasses: the protected `set_priority` is now `priority=`, and cache keys use the uppercase HTTP method (`GET:/users/x`).

###  v0.4.1  (2021-11-18)
- bug fix

###  v0.4.0  (2021-11-18)
- rspec helper
- test coverage for redirects

###  v0.3.2  (2021-11-17)
- rails prioritizer

###  v0.3.1  (2021-11-17)
- bug fixes

###  v0.3.0  (2021-11-17)
- prioritizer

###  v0.2.0  (2021-10-18)
- limiter proc
- Update README.md
- rename error types
- test coverage
- railtie spec

###  v0.1.0  (2021-10-02)
- ability to limit rack requests
- clean up spec
- configure via initializer
- custom error testing
- custom error types
- condense namespace

###  v0.0.2  (2021-09-12)
- header support

###  v0.0.1  (2021-09-11)
- init

