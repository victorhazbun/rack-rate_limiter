# frozen_string_literal: true

RSpec.describe Rack::RateLimiter do
  it 'has a version number' do
    expect(Rack::RateLimiter::VERSION).not_to be nil
  end
end
