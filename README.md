# Rack::RateLimiter

![build status](https://github.com/victorhazbun/rack-rate_limiter/actions/workflows/main.yml/badge.svg)

This is an implementation of a rate limiter in Ruby that allows for rate limiting with a rolling window. It can use either Redis limiter or custom limiter. If Redis is used, multiple rate limiters can share one instance with different namespaces, and multiple processes can share rate limiter state safely.

This means that if a user is allowed 5 actions per 60 seconds, any action will be blocked if 5 actions have already occured in the preceeding 60 seconds, without any set points at which this interval resets. This contrasts with some other rate limiter implementations, in which a user could make 5 requests at 0:59 and another 5 requests at 1:01.

**Important Note:** As a consequence of the way the Redis algorithm works, if an action is blocked, it is still "counted". This means that if a user is continually attempting actions more quickly than the allowed rate, all of their actions will be blocked until they pause or slow their requests.

## How it works

- Each identifier/user corresponds to a sorted set data structure. The keys and values are both equal to the (microsecond) times at which actions were attempted, allowing easy manipulation of this list.
- When a new action comes in for a user, all elements in the set that occurred earlier than (current time - interval) are dropped from the set.
- If the number of elements in the set is still greater than the maximum, the current action is blocked.
- If a minimum difference has been set and the most recent previous element is too close to the current time, the current action is blocked.
- The current action is then added to the set.
- Note: if an action is blocked, it is still added to the set. This means that if a user is continually attempting actions more quickly than the allowed rate, all of their actions will be blocked until they pause or slow their requests.
- If the limiter uses a redis instance, the keys are prefixed with namespace, allowing a single redis instance to support separate rate limiters.
- All redis operations for a single rate-limit check/update are performed as an atomic transaction, allowing rate limiters running on separate processes or machines to share state safely.

Credits: [Peter Hayes](https://github.com/peterkhayes/rolling-rate-limiter)

**Benefits**

- Atomic operations. ✅✅✅
- Use Redis sorted sets to prevent race conditions. 🏃🏼‍♂️🏃🏻‍♀️
- Multiple rate limiters can share one Redis instance with different namespaces. 📁
- More efficient and scalable. 🚀

**Caveats**

Blocked actions still count as actions. So, if a user continually exceeds the rate limit, none of their actions will be allowed (after the first few), instead of allowing occasional actions through.

## Installation

TODO: Publish to rubygems

## Usage

### Using Redis limiter

To use the middleware, add it to your `config/application.rb`:

```ruby
# Max request limit.
limit = 5

# Interval in seconds.
interval = 60

redis = Redis.new

# Uses Redis sorted sets for rate limiting.
# See: https://redis.io/docs/data-types/sorted-sets/
limiter = Rack::RateLimiter::RedisLimiter.new(limit:, interval:, redis:)

# Redis key is resolved using the user IP address from the http request
key_resolver = Rack::RateLimiter::HTTPRequestResolver.new('REMOTE_ADDR')

# HTTP request resolver supports optional "namespace":
#   namespace = 'your-namespace' # A string to prepend to all keys to prevent conflicts with other code using Redis.
#   key_resolver = Rack::RateLimiter::HTTPRequestResolver.new('REMOTE_ADDR', namespace:)

# Set failed response, returned when limit is exceeded.
failed_response = [429, { 'Content-Type' => 'text/plain' }, 'Too Many Requests']

options = { limiter:, key_resolver:, failed_response: }

Rails.application.config.middleware.use(Rack::RateLimiter, options:)
```

### Using custom limiter

```ruby
limiter = YourCustomLimiter.new # MUST respond to #allowed?(key) method.

options = { limiter:, key_resolver:, failed_response: }

Rails.application.config.middleware.use(Rack::RateLimiter, options:)
```

### Using custom key resolver

```ruby
key_resolver = YourCustomKeyResolver.new # MUST respond to #call method.

options = { limiter:, key_resolver:, failed_response: }

Rails.application.config.middleware.use(Rack::RateLimiter, options:)

```

### Using custom logger

```ruby
logger = Rails.logger # MUST respond to #error

limiter = Rack::RateLimiter::RedisLimiter.new(limit:, interval:, redis:, logger:)

options = { limiter:, key_resolver:, failed_response: }

Rails.application.config.middleware.use(Rack::RateLimiter, options:)

```

## Contributing

TODO: Navigate to `myapp` (small Rails app inside `Rack::RateLimiter` repository used for development)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
