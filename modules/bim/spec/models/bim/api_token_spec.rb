# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::ApiToken, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:api_token) { create(:bim_api_token, user: user, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:token_hash) }
    it { is_expected.to validate_presence_of(:token_prefix) }

    it 'validates name length' do
      token = build(:bim_api_token, name: 'a' * 256)
      expect(token).not_to be_valid
    end

    it 'validates token_hash uniqueness' do
      existing = create(:bim_api_token)
      duplicate = build(:bim_api_token, token_hash: existing.token_hash)

      expect(duplicate).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_token) { create(:bim_api_token, :read_only, active: true) }
    let!(:revoked_token) { create(:bim_api_token, :revoked) }
    let!(:expired_token) { create(:bim_api_token, :expired) }
    let!(:valid_token) { create(:bim_api_token, :long_expiry) }

    describe '.active' do
      it 'returns only active tokens' do
        expect(described_class.active).to include(active_token, valid_token)
        expect(described_class.active).not_to include(revoked_token)
      end
    end

    describe '.expired' do
      it 'returns only expired tokens' do
        expect(described_class.expired).to include(expired_token)
        expect(described_class.expired).not_to include(valid_token)
      end
    end

    describe '.not_expired' do
      it 'returns tokens that have not expired' do
        expect(described_class.not_expired).to include(active_token, valid_token)
        expect(described_class.not_expired).not_to include(expired_token)
      end
    end

    describe '.for_user' do
      let(:other_user) { create(:user) }
      let!(:user_token) { create(:bim_api_token, user: user) }
      let!(:other_token) { create(:bim_api_token, user: other_user) }

      it 'returns tokens for specified user' do
        expect(described_class.for_user(user.id)).to include(user_token)
        expect(described_class.for_user(user.id)).not_to include(other_token)
      end
    end

    describe '.for_project' do
      let!(:project_token) { create(:bim_api_token, project: project) }
      let!(:global_token) { create(:bim_api_token, :global_token) }

      it 'returns tokens for specified project' do
        expect(described_class.for_project(project.id)).to include(project_token)
        expect(described_class.for_project(project.id)).not_to include(global_token)
      end
    end

    describe '.recent' do
      it 'orders tokens by created_at descending' do
        old_token = create(:bim_api_token)
        old_token.update(created_at: 2.days.ago)

        new_token = create(:bim_api_token)

        expect(described_class.recent.first).to eq(new_token)
      end
    end
  end

  describe '.generate' do
    it 'creates a new API token' do
      expect do
        described_class.generate(
          user: user,
          name: 'Test Token',
          scopes: ['read:models']
        )
      end.to change(described_class, :count).by(1)
    end

    it 'returns both token object and plain token' do
      token_obj, plain_token = described_class.generate(
        user: user,
        name: 'Test Token'
      )

      expect(token_obj).to be_a(described_class)
      expect(plain_token).to be_a(String)
      expect(plain_token.length).to be > 20
    end

    it 'hashes the token before storing' do
      token_obj, plain_token = described_class.generate(
        user: user,
        name: 'Test Token'
      )

      expect(token_obj.token_hash).not_to eq(plain_token)
      expect(token_obj.token_hash.length).to eq(64) # SHA256 hex
    end

    it 'sets token prefix from first 8 chars' do
      token_obj, plain_token = described_class.generate(
        user: user,
        name: 'Test Token'
      )

      expect(token_obj.token_prefix).to eq(plain_token[0..7])
    end

    it 'accepts optional expiration' do
      token_obj, _plain = described_class.generate(
        user: user,
        name: 'Test Token',
        expires_in: 30.days
      )

      expect(token_obj.expires_at).to be_within(1.minute).of(30.days.from_now)
    end

    it 'accepts project scope' do
      token_obj, _plain = described_class.generate(
        user: user,
        name: 'Test Token',
        project: project
      )

      expect(token_obj.project).to eq(project)
    end

    it 'accepts scopes array' do
      token_obj, _plain = described_class.generate(
        user: user,
        name: 'Test Token',
        scopes: ['read:models', 'write:models']
      )

      expect(token_obj.scopes).to eq(['read:models', 'write:models'])
    end
  end

  describe '.find_by_token' do
    let!(:token_obj) do
      described_class.generate(
        user: user,
        name: 'Test Token'
      ).first
    end

    it 'returns nil for invalid token' do
      expect(described_class.find_by_token('invalid')).to be_nil
    end

    it 'returns nil for revoked token' do
      token_obj, plain_token = described_class.generate(
        user: user,
        name: 'Test Token'
      )

      token_obj.revoke!

      expect(described_class.find_by_token(plain_token)).to be_nil
    end

    it 'returns nil for expired token' do
      token_obj, plain_token = described_class.generate(
        user: user,
        name: 'Test Token',
        expires_in: -1.day
      )

      expect(described_class.find_by_token(plain_token)).to be_nil
    end
  end

  describe '.hash_token' do
    it 'returns SHA256 hash' do
      hash = described_class.hash_token('test_token')

      expect(hash).to be_a(String)
      expect(hash.length).to eq(64)
    end

    it 'returns consistent hash for same input' do
      hash1 = described_class.hash_token('test_token')
      hash2 = described_class.hash_token('test_token')

      expect(hash1).to eq(hash2)
    end

    it 'returns different hash for different input' do
      hash1 = described_class.hash_token('token1')
      hash2 = described_class.hash_token('token2')

      expect(hash1).not_to eq(hash2)
    end
  end

  describe '.cleanup_expired' do
    it 'deletes old expired tokens' do
      old_expired = create(:bim_api_token, expires_at: 35.days.ago)

      expect do
        described_class.cleanup_expired(older_than: 30.days.ago)
      end.to change(described_class, :count).by(-1)
    end

    it 'keeps recently expired tokens' do
      recent_expired = create(:bim_api_token, expires_at: 25.days.ago)

      described_class.cleanup_expired(older_than: 30.days.ago)

      expect(described_class.exists?(recent_expired.id)).to be true
    end

    it 'keeps valid tokens' do
      valid = create(:bim_api_token, :long_expiry)

      described_class.cleanup_expired

      expect(described_class.exists?(valid.id)).to be true
    end
  end

  describe '#has_scope?' do
    it 'returns true when scope is present' do
      token = create(:bim_api_token, scopes: ['read:models', 'write:models'])

      expect(token.has_scope?('read:models')).to be true
      expect(token.has_scope?('write:models')).to be true
    end

    it 'returns false when scope is absent' do
      token = create(:bim_api_token, scopes: ['read:models'])

      expect(token.has_scope?('write:models')).to be false
    end

    it 'returns true for any scope when admin:all is present' do
      token = create(:bim_api_token, :admin_token)

      expect(token.has_scope?('read:models')).to be true
      expect(token.has_scope?('write:models')).to be true
      expect(token.has_scope?('delete:models')).to be true
    end
  end

  describe '#can?' do
    it 'checks scope in action:resource format' do
      token = create(:bim_api_token, scopes: ['read:models'])

      expect(token.can?(:read, :models)).to be true
      expect(token.can?(:write, :models)).to be false
    end

    it 'works with admin:all scope' do
      token = create(:bim_api_token, :admin_token)

      expect(token.can?(:read, :models)).to be true
      expect(token.can?(:delete, :models)).to be true
    end
  end

  describe '#touch_last_used!' do
    it 'updates last_used_at timestamp' do
      token = create(:bim_api_token, :unused)

      expect do
        token.touch_last_used!
      end.to change { token.reload.last_used_at }.from(nil)
    end

    it 'updates last_used_ip when provided' do
      token = create(:bim_api_token, :unused)

      token.touch_last_used!(ip_address: '192.168.1.100')

      expect(token.reload.last_used_ip).to eq('192.168.1.100')
    end

    it 'increments usage_count' do
      token = create(:bim_api_token, usage_count: 5)

      expect do
        token.touch_last_used!
      end.to change { token.reload.usage_count }.from(5).to(6)
    end
  end

  describe '#revoke!' do
    it 'sets active to false' do
      token = create(:bim_api_token, active: true)

      token.revoke!

      expect(token.reload.active).to be false
    end
  end

  describe '#valid_token?' do
    it 'returns true for active, non-expired token' do
      token = create(:bim_api_token, :long_expiry, active: true)

      expect(token.valid_token?).to be true
    end

    it 'returns false for revoked token' do
      token = create(:bim_api_token, :revoked)

      expect(token.valid_token?).to be false
    end

    it 'returns false for expired token' do
      token = create(:bim_api_token, :expired, active: true)

      expect(token.valid_token?).to be false
    end
  end

  describe '#expired?' do
    it 'returns false when no expiration set' do
      token = create(:bim_api_token, :never_expires)

      expect(token.expired?).to be false
    end

    it 'returns false when expiration is in future' do
      token = create(:bim_api_token, :long_expiry)

      expect(token.expired?).to be false
    end

    it 'returns true when expiration is in past' do
      token = create(:bim_api_token, :expired)

      expect(token.expired?).to be true
    end
  end

  describe '#days_until_expiration' do
    it 'returns nil when token never expires' do
      token = create(:bim_api_token, :never_expires)

      expect(token.days_until_expiration).to be_nil
    end

    it 'returns positive number for future expiration' do
      token = create(:bim_api_token, expires_at: 10.days.from_now)

      expect(token.days_until_expiration).to be_between(9, 11)
    end

    it 'returns negative number for past expiration' do
      token = create(:bim_api_token, :expired)

      expect(token.days_until_expiration).to be < 0
    end
  end

  describe '#status' do
    it 'returns "revoked" for inactive tokens' do
      token = create(:bim_api_token, :revoked)

      expect(token.status).to eq('revoked')
    end

    it 'returns "expired" for expired tokens' do
      token = create(:bim_api_token, :expired, active: true)

      expect(token.status).to eq('expired')
    end

    it 'returns "active" for valid tokens' do
      token = create(:bim_api_token, :long_expiry, active: true)

      expect(token.status).to eq('active')
    end
  end

  describe '#expiration_info' do
    it 'returns "Never expires" when no expiration set' do
      token = create(:bim_api_token, :never_expires)

      expect(token.expiration_info).to eq('Never expires')
    end

    it 'shows days until expiration for future dates' do
      token = create(:bim_api_token, :expiring_soon)

      expect(token.expiration_info).to match(/Expires in \d+ days/)
    end

    it 'shows time since expiration for past dates' do
      token = create(:bim_api_token, :expired)

      expect(token.expiration_info).to match(/Expired .+ ago/)
    end
  end

  describe '#to_hash' do
    it 'exports token as hash with all attributes' do
      hash = api_token.to_hash

      expect(hash).to include(
        :id,
        :name,
        :description,
        :token_prefix,
        :scopes,
        :active,
        :status,
        :expires_at,
        :expiration_info,
        :created_at,
        :last_used_at,
        :usage_count,
        :user,
        :project
      )
    end

    it 'includes user information' do
      hash = api_token.to_hash

      expect(hash[:user]).to include(
        id: user.id,
        name: user.name,
        login: user.login
      )
    end

    it 'includes project information when present' do
      hash = api_token.to_hash

      expect(hash[:project]).to include(
        id: project.id,
        name: project.name
      )
    end

    it 'handles nil project for global tokens' do
      token = create(:bim_api_token, :global_token)
      hash = token.to_hash

      expect(hash[:project]).to be_nil
    end

    it 'does not include token_hash' do
      hash = api_token.to_hash

      expect(hash).not_to have_key(:token_hash)
    end

    it 'formats timestamps as ISO8601' do
      hash = api_token.to_hash

      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end

  describe 'AVAILABLE_SCOPES constant' do
    it 'defines all available scopes' do
      expect(described_class::AVAILABLE_SCOPES).to include(
        'read:models',
        'write:models',
        'delete:models',
        'read:clashes',
        'run:clashes',
        'read:baselines',
        'write:baselines',
        'read:federations',
        'write:federations',
        'read:dashboards',
        'write:dashboards',
        'admin:all'
      )
    end
  end
end
