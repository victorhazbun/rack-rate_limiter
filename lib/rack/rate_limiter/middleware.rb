# frozen_string_literal: true

class Middleware
  def initialize(app, options: {})
    @app = app
    @limiter = options[:limiter]
    @failed_response = options[:failed_response]
  end

  def call(env)
    return @failed_response unless @limiter.allowed?

    @app.call(env)
  end
end
