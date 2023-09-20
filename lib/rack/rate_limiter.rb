# frozen_string_literal: true

require_relative 'rate_limiter/version'
require_relative 'rate_limiter/redis_limiter'
require_relative 'rate_limiter/middleware'

module Rack
  module RateLimiter
    class Error < StandardError; end
  end
end
