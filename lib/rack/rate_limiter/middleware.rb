# frozen_string_literal: true

class Middleware
  def initialize(app, options: {})
    @app = app
    @limiter = options[:limiter]
    @key_resolver = options[:key_resolver]
    @failed_response = options[:failed_response]
  end

  def call(env)
    return @failed_response unless @limiter.allowed?(@key_resolver.call(env))

    @app.call(env)
  end
end
