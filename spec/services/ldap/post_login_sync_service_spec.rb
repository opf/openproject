require 'spec_helper'

RSpec.describe Ldap::PostLoginSyncService do
  let!(:ldap) { create(:ldap_auth_source) }
  let(:admin) { false }
  let(:attributes) do
    {
      login: 'aa729',
      admin:,
      firstname: 'Alexandra',
      lastname: 'Adams',
      mail: 'a.adam@example.com',
      ldap_auth_source_id: ldap.id
    }
  end

  subject do
    described_class.new(ldap, user:, attributes:).call
  end

  context 'with an existing user' do
    let!(:user) { create(:user, firstname: 'Bob', lastname: 'Bobbit', mail: 'b@example.com', login: 'aa729') }

    it 'syncs the attributes' do
      expect(user.firstname).to eq 'Bob'
      expect(user.lastname).to eq 'Bobbit'
      expect(user.mail).to eq 'b@example.com'

      expect(subject).to be_success
      expect(subject.result).to be_a User
      expect(subject.result).to be_valid
      expect(subject.result.firstname).to eq 'Alexandra'
      expect(subject.result.lastname).to eq 'Adams'
      expect(subject.result.mail).to eq 'a.adam@example.com'
    end

    context 'with nil attributes' do
      let(:attributes) { nil }

      it 'locks the user when enabled', with_config: { ldap_users_sync_status: true } do
        expect(user).to be_active

        subject

        expect(user.reload).to be_locked
      end

      it 'does nothing when not enabled', with_config: { ldap_users_sync_status: false } do
        expect(user).to be_active

        expect { subject }.not_to change(user, :attributes)
      end
    end

    context 'with empty attributes' do
      let(:attributes) { {} }

      it 'locks the user when enabled', with_config: { ldap_users_sync_status: true } do
        expect(user).to be_active

        subject

        expect(user.reload).to be_locked
      end

      it 'does nothing when not enabled', with_config: { ldap_users_sync_status: false } do
        expect(user).to be_active

        expect { subject }.not_to change(user, :attributes)
      end
    end
  end

  context 'with a new user' do
    let!(:user) { build(:user, firstname: 'Bob', lastname: 'Bobbit', mail: 'b@example.com', login: 'aa729') }

    it 'creates the user' do
      expect(user.firstname).to eq 'Bob'
      expect(user.lastname).to eq 'Bobbit'
      expect(user.mail).to eq 'b@example.com'
      expect(user).to be_new_record

      expect(subject).to be_success
      expect(subject.result).to be_a User
      expect(subject.result).to be_valid
      expect(subject.result.firstname).to eq 'Alexandra'
      expect(subject.result.lastname).to eq 'Adams'
      expect(subject.result.mail).to eq 'a.adam@example.com'
      expect(subject.result).to be_persisted
    end
  end
end
