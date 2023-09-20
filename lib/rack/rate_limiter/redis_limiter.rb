# frozen_string_literal: true

require 'redis'
# Better rate limiting with Redis sorted sets.
# @see https://engineering.classdojo.com/blog/2015/02/06/rolling-rate-limiter/
class RedisLimiter
  attr_accessor :key, :limit, :interval, :redis

  def initialize(key:, limit:, interval:, redis:)
    @key = key
    @limit = limit
    @interval = interval
    @redis = redis
  end

  # rubocop:disable Metrics/AbcSize
  def allowed?
    now = Time.now.to_f

    # Drop all elements of the sorted set which occurred before one interval ago.
    redis.zremrangebyscore(key, 0, now - interval)

    # Fetch all elements of the set.
    elements = redis.zrange(key, 0, -1)

    # Add the current timestamp to the set.
    redis.zadd(key, now, now)

    # Set a TTL equal to the rate-limiting interval on the set.
    redis.expire(key, interval)

    # Count the number of fetched elements.
    num_elements = elements.count

    # If the number of elements exceeds the limit, don't allow the action.
    return false if num_elements >= limit

    # If the largest fetched element is less than 90% of the interval ago, don't allow the action.
    return false if elements.any? && (elements.last.to_f <= (now - (interval * 0.9)))

    true
  end
  # rubocop:enable Metrics/AbcSize
end
