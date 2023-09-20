# frozen_string_literal: true

class HTTPRequestResolver
  def initialize(env_key, namespace:)
    @env_key = env_key
    @namespace = namespace
  end

  def call(env)
    key = env[@env_key]
    if @namespace
      "#{@namespace}:#{key}"
    else
      key
    end
  end
end
