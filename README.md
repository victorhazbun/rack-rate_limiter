# Rack::RateLimiter

A Ruby on Rails middleware that uses Redis (sorted sets) to implement rate limiting.

## Motivation

Traditional rate limiters using counters can be susceptible to race conditions, where two processes simultaneously attempt to increment a counter, resulting in an incorrect count. This can lead to users being able to perform more actions than they are allowed.

Sorted sets provide a more robust and scalable way to implement rate limiters. By using a sorted set to store the times of recent actions, we can ensure that all operations are performed atomically, preventing race conditions. This also allows us to use one limiter for multiple rates, such as limiting the number of actions per minute and per second.

## How it works

To implement a rate limiter using a sorted set, we can use the following algorithm:

- Create a sorted set for each user.
- When a user attempts to perform an action:
  - Drop all elements of the set which occurred before one interval ago.
- Fetch all elements of the set.
- Add the current timestamp to the set.
- Set a TTL equal to the rate-limiting interval on the set.
- Count the number of fetched elements. If it exceeds the limit, don't allow the action.
- Compare the largest fetched element to the current timestamp. If they're too close, don't allow the action.

Credits: Peter Hayes - https://engineering.classdojo.com/blog/2015/02/06/rolling-rate-limiter/

**Benefits**

Atomic operations prevent race conditions.
One limiter for multiple rates.
More efficient and scalable.

**Caveats**

Blocked actions still count as actions. So, if a user continually exceeds the rate limit, none of their actions will be allowed (after the first few), instead of allowing occasional actions through.

## Installation

To install the gem, run the following command:

`gem install rack-rate_limiter`

## Usage

### Using Redis limiter

To use the middleware, add it to your `config/application.rb`:

```ruby
# Max request limit.
limit = 100

# Interval in seconds.
interval = 60

redis = Redis.new

# Uses Redis sorted sets for rate limiting.
# See: https://redis.io/docs/data-types/sorted-sets/
limiter = Rack::RateLimiter::RedisLimiter.new(limit:, interval:, redis:)

# Redis key is resolved using the user IP address from the http request
key_resolver = Rack::RateLimiter::HTTPRequestResolver.new('REMOTE_ADDR')

# Key resolver also supports optional key "namespace":
#   namespace = 'your-namespace'
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

## Contributing

TODO: Navigate to `myapp` (small Rails app inside `Rack::RateLimiter` repository used for development)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
