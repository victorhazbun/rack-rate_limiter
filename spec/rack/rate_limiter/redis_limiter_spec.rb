# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'redis'

RSpec.describe RedisLimiter do
  let(:namespace) { SecureRandom.uuid }
  let(:redis) { Redis.new }
  let(:key) { "#{namespace}:my-key" }
  let(:limit) { 3 }
  let(:interval) { 60 }

  let(:redis_limiter) { described_class.new(limit:, interval:, redis:) }

  after do
    redis.keys("#{namespace}:*").each do |key|
      redis.del(key)
    end
  end

  describe '#allowed?' do
    context 'when checking serially' do
      it 'is allowed until exceeds the limit' do
        results = (limit + 1).times.map do
          redis_limiter.allowed?(key)
        end
        expect(results).to eq([true, true, true, false])
      end
    end

    context 'when checking concurrently' do
      let(:limit) { 12 }
      let(:concurrent) { 4 }
      let(:threads) { [] }
      let(:results) { [] }

      it 'is allowed until exceeds the limit' do
        # Start multiple threads to simulate concurrent requests
        concurrent.times do |_i|
          threads << Thread.new do
            # Simulate calls made by different threads
            calls = (limit / concurrent) + 1
            calls.times do
              results << redis_limiter.allowed?(key)
            end
          end
        end

        # Wait for all threads to finish
        threads.each(&:join)

        expect(results.count).to eq(16)
        # 4 threads and 3 requests per thread = 12 requests (succeed)
        expect(results.slice(0, 11)).to all be_truthy
        # 4 threads and 1 extra request per thread = 4 requests (fail).
        expect(results.slice(12, 15)).to all be_falsey
      end
    end

    context 'when the largest fetched element is less or equal than 90% of the interval ago' do
      it 'is not allowed' do
        # Freeze time to the interval ago.
        Timecop.freeze(Time.now - interval) do
          # Add an element to the sorted set that is less than 90% of the interval ago.
          redis.zadd(key, Time.now.to_f - (interval * 0.9), Time.now.to_f - (interval * 0.9))

          # Expect the `allowed?` method to return false.
          expect(redis_limiter.allowed?(key)).to be false
        end
      end
    end
  end
end
