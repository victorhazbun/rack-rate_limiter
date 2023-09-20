# frozen_string_literal: true

require 'rspec'

RSpec.describe HTTPRequestResolver do
  let(:env_key) { 'REMOTE_ADDR' }
  let(:namespace) { 'my_namespace' }
  let(:key_resolver) { described_class.new(env_key, namespace:) }

  describe '#call' do
    context 'with a namespace' do
      it 'prepends the namespace to the key' do
        env = { env_key => '1234567890' }

        expect(key_resolver.call(env)).to eq 'my_namespace:1234567890'
      end
    end

    context 'without a namespace' do
      let(:namespace) { nil }

      it 'returns the key' do
        env = { env_key => '1234567890' }
        expect(key_resolver.call(env)).to eq '1234567890'
      end
    end
  end
end
