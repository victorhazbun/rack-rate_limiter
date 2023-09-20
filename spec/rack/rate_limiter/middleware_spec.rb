# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'rack'

RSpec.describe Middleware do
  let(:app) { ->(env) { [200, env, 'app'] } }
  let(:env) { Rack::MockRequest.env_for('example.com') }
  let(:namespace) { SecureRandom.uuid }
  let(:redis) { Redis.new }
  let(:key) { "#{namespace}:my-key" }
  let(:limit) { 2 }
  let(:interval) { 60 }
  let(:limiter) { RedisLimiter.new(key:, limit:, interval:, redis:) }
  let(:options) do
    {
      limiter:,
      failed_response: [429, { 'Content-Type' => 'text/plain' }, 'Too Many Requests']
    }
  end
  let(:middleware) { described_class.new(app, options:) }

  before do
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
