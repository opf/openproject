# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::Authentication::DatabaseAdapter do
  let(:user) { create(:user, login: 'testuser') }
  let(:adapter) { described_class.new }

  describe '#authenticate' do
    context 'with valid username and password' do
      before do
        allow(User).to receive(:try_to_login)
          .with('testuser', 'password123')
          .and_return(user)
      end

      it 'authenticates successfully' do
        result = adapter.authenticate(
          username: 'testuser',
          password: 'password123'
        )

        expect(result).to eq(user)
      end
    end

    context 'with invalid credentials' do
      before do
        allow(User).to receive(:try_to_login).and_return(nil)
      end

      it 'returns nil for wrong password' do
        result = adapter.authenticate(
          username: 'testuser',
          password: 'wrongpassword'
        )

        expect(result).to be_nil
      end

      it 'returns nil for non-existent user' do
        result = adapter.authenticate(
          username: 'nonexistent',
          password: 'password123'
        )

        expect(result).to be_nil
      end

      it 'returns nil when username is missing' do
        result = adapter.authenticate(password: 'password123')

        expect(result).to be_nil
      end

      it 'returns nil when password is missing' do
        result = adapter.authenticate(username: 'testuser')

        expect(result).to be_nil
      end

      it 'returns nil when both are missing' do
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
    it 'has standard priority (10)' do
      expect(adapter.priority).to eq(10)
    end
  end

  describe '#supports_2fa?' do
    it 'does not support 2FA directly' do
      expect(adapter.supports_2fa?).to be false
    end
  end
end
