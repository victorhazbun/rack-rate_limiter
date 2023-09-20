# frozen_string_literal: true

require 'redis'
require 'logger'
# Better rate limiting with Redis sorted sets.
# @see https://engineering.classdojo.com/blog/2015/02/06/rolling-rate-limiter/
class RedisLimiter
  def initialize(limit:, interval:, redis:, logger: Logger.new($stdout))
    @limit = limit
    @interval = interval
    @redis = redis
    @logger = logger
  end

  def allowed?(key, now = Time.now.to_f)
    @redis.multi do
      # Drop all elements of the sorted set which occurred before one interval ago.
      @redis.zremrangebyscore(key, 0, now - @interval)

      # Fetch all elements of the set.
      elements = @redis.zrange(key, 0, -1)

      # Add the current timestamp to the set.
      @redis.zadd(key, now, now)

      # Set a TTL equal to the rate-limiting interval on the set.
      @redis.expire(key, @interval)

      # If the number of elements exceeds the limit, don't allow the action.
      # OR if the largest fetched element is less than 90% of the interval ago, don't allow the action.
      return !(exceeds_limit?(elements.count) || over_burst_limit?(elements, now))
    end
  rescue Redis::BaseError => e
    @logger.error("Redis error: #{e.message}")
    false
  end

  private

  def exceeds_limit?(elements_count)
    elements_count >= @limit
  end

  def over_burst_limit?(elements, now)
    elements.any? && (elements.last.to_f <= (now - (@interval * 0.9)))
  end
end
