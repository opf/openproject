# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::Authentication::ApiTokenAdapter do
  let(:user) { create(:user) }
  let(:adapter) { described_class.new }

  describe '#authenticate' do
    context 'with valid API token' do
      let!(:token_obj) do
        Bim::ApiToken.generate(
          user: user,
          name: 'Test Token',
          scopes: ['read:models']
        )
      end
      let(:plain_token) { token_obj[1] }

      it 'authenticates successfully' do
        result = adapter.authenticate(api_token: plain_token)

        expect(result).to eq(user)
      end

      it 'updates last_used_at' do
        token = token_obj[0]

        expect do
          adapter.authenticate(api_token: plain_token)
        end.to change { token.reload.last_used_at }.from(nil)
      end

      it 'records IP address when provided' do
        token = token_obj[0]

        adapter.authenticate(
          api_token: plain_token,
          ip_address: '192.168.1.100'
        )

        expect(token.reload.last_used_ip).to eq('192.168.1.100')
      end

      it 'increments usage count' do
        token = token_obj[0]

        expect do
          adapter.authenticate(api_token: plain_token)
        end.to change { token.reload.usage_count }.by(1)
      end
    end

    context 'with invalid API token' do
      it 'returns nil for non-existent token' do
        result = adapter.authenticate(api_token: 'invalid_token')

        expect(result).to be_nil
      end

      it 'returns nil for expired token' do
        token_obj = Bim::ApiToken.generate(
          user: user,
          name: 'Expired Token',
          expires_in: -1.day
        )
        plain_token = token_obj[1]

        result = adapter.authenticate(api_token: plain_token)

        expect(result).to be_nil
      end

      it 'returns nil for revoked token' do
        token_obj = Bim::ApiToken.generate(
          user: user,
          name: 'Revoked Token'
        )
        token = token_obj[0]
        plain_token = token_obj[1]

        token.revoke!

        result = adapter.authenticate(api_token: plain_token)

        expect(result).to be_nil
      end

      it 'returns nil when no token provided' do
        result = adapter.authenticate({})

        expect(result).to be_nil
      end
    end
  end

  describe '#enabled?' do
    it 'is always enabled' do
      expect(adapter.enabled?).to be true
    end
  end

  describe '#priority' do
    it 'has highest priority (5)' do
      expect(adapter.priority).to eq(5)
    end
  end

  describe '#supports_2fa?' do
    it 'does not support 2FA' do
      expect(adapter.supports_2fa?).to be false
    end
  end
end
