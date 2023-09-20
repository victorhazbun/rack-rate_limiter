# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'rack'

RSpec.describe Middleware do
  let(:app) { ->(env) { [200, env, 'app'] } }
  let(:env) { Rack::MockRequest.env_for('example.com', 'REMOTE_ADDR' => '0.0.0.0') }
  let(:namespace) { SecureRandom.uuid }
  let(:limit) { 2 }
  let(:interval) { 60 }
  let(:redis) { Redis.new }
  let(:key_resolver) { HTTPRequestResolver.new('REMOTE_ADDR', namespace:) }
  let(:limiter) { RedisLimiter.new(limit:, interval:, redis:) }
  let(:failed_response) { [429, { 'Content-Type' => 'text/plain' }, 'Too Many Requests'] }
  let(:options) { { key_resolver:, limiter:, failed_response: } }
  let(:middleware) { described_class.new(app, options:) }

  after do
    redis.keys("#{namespace}:*").each do |key|
      redis.del(key)
    end
  end

  describe '#call' do
    it 'is allowed until exceeds the limit' do
      results = (limit + 1).times.map do
        middleware.call(env)
      end
      status_codes = results.map { |item| item[0] }

      expect(status_codes).to eq([200, 200, 429])
    end
  end
end
