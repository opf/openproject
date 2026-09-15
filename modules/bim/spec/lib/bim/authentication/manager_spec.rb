# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::Authentication::Manager do
  let(:user) { create(:user, login: 'testuser') }

  describe '.authenticate' do
    context 'with username and password' do
      before do
        allow(User).to receive(:try_to_login).with('testuser', 'password123').and_return(user)
      end

      it 'authenticates valid credentials' do
        result = described_class.authenticate(
          username: 'testuser',
          password: 'password123'
        )

        expect(result).to eq(user)
      end

      it 'returns nil for invalid credentials' do
        allow(User).to receive(:try_to_login).and_return(nil)

        result = described_class.authenticate(
          username: 'testuser',
          password: 'wrongpassword'
        )

        expect(result).to be_nil
      end
    end

    context 'with API token' do
      let!(:token_obj) do
        Bim::ApiToken.generate(
          user: user,
          name: 'Test Token',
          scopes: ['read:models']
        )
      end

      it 'authenticates valid API token' do
        plain_token = token_obj[1]

        result = described_class.authenticate(api_token: plain_token)

        expect(result).to eq(user)
      end

      it 'returns nil for invalid API token' do
        result = described_class.authenticate(api_token: 'invalid_token')

        expect(result).to be_nil
      end

      it 'returns nil for expired token' do
        token = token_obj[0]
        token.update!(expires_at: 1.day.ago)

        plain_token = token_obj[1]
        result = described_class.authenticate(api_token: plain_token)

        expect(result).to be_nil
      end

      it 'updates token usage on successful authentication' do
        plain_token = token_obj[1]
        token = token_obj[0]

        expect do
          described_class.authenticate(
            api_token: plain_token,
            ip_address: '192.168.1.100'
          )
        end.to change { token.reload.usage_count }.by(1)

        expect(token.last_used_ip).to eq('192.168.1.100')
        expect(token.last_used_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'with no credentials' do
      it 'returns nil' do
        result = described_class.authenticate({})

        expect(result).to be_nil
      end
    end

    context 'with multiple adapters' do
      it 'tries adapters in priority order' do
        # API token adapter has highest priority (5)
        # Database adapter has priority 10
        token_obj = Bim::ApiToken.generate(
          user: user,
          name: 'Test Token',
          scopes: ['read:models']
        )
        plain_token = token_obj[1]

        # Should try API token first and succeed
        result = described_class.authenticate(api_token: plain_token)

        expect(result).to eq(user)
      end

      it 'falls through to next adapter if first fails' do
        allow(User).to receive(:try_to_login).with('testuser', 'password123').and_return(user)

        # API token adapter will fail (no token provided)
        # Database adapter should succeed
        result = described_class.authenticate(
          username: 'testuser',
          password: 'password123'
        )

        expect(result).to eq(user)
      end
    end
  end

  describe '.adapters' do
    it 'returns all enabled adapters' do
      adapters = described_class.adapters

      expect(adapters).to be_an(Array)
      expect(adapters).not_to be_empty
    end

    it 'orders adapters by priority' do
      adapters = described_class.adapters
      priorities = adapters.map(&:priority)

      expect(priorities).to eq(priorities.sort)
    end

    it 'includes database adapter by default' do
      adapter_classes = described_class.adapters.map(&:class)

      expect(adapter_classes).to include(Bim::Authentication::DatabaseAdapter)
    end

    it 'includes API token adapter by default' do
      adapter_classes = described_class.adapters.map(&:class)

      expect(adapter_classes).to include(Bim::Authentication::ApiTokenAdapter)
    end

    it 'excludes disabled adapters' do
      # SSO is disabled by default (ENV['BIM_SSO_ENABLED'] not set)
      adapter_classes = described_class.adapters.map(&:class)

      expect(adapter_classes).not_to include(Bim::Authentication::SsoAdapter)
    end

    context 'when SSO is enabled' do
      around do |example|
        ENV['BIM_SSO_ENABLED'] = 'true'
        example.run
        ENV.delete('BIM_SSO_ENABLED')
      end

      it 'includes SSO adapter' do
        # Clear memoization
        described_class.instance_variable_set(:@adapters, nil)

        adapter_classes = described_class.adapters.map(&:class)

        expect(adapter_classes).to include(Bim::Authentication::SsoAdapter)
      end
    end
  end

  describe '.register_adapter' do
    let(:custom_adapter_class) do
      Class.new(Bim::Authentication::Adapter) do
        def authenticate(credentials)
          credentials[:custom_key] == 'custom_value' ? User.first : nil
        end

        def priority
          1 # Highest priority
        end
      end
    end

    it 'registers a custom adapter' do
      described_class.register_adapter(custom_adapter_class)

      adapter_classes = described_class.adapters.map(&:class)
      expect(adapter_classes).to include(custom_adapter_class)
    end

    it 'custom adapter is used in authentication' do
      described_class.register_adapter(custom_adapter_class)

      result = described_class.authenticate(custom_key: 'custom_value')

      expect(result).to eq(User.first)
    end
  end
end
