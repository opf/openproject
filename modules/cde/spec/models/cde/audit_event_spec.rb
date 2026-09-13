# frozen_string_literal: true

RSpec.describe Cde::AuditEvent, type: :model do
  describe 'validations' do
    let(:container) { create(:cde_container) }
    let(:user) { create(:user) }

    subject do
      build(:cde_audit_event, auditable: container, user: user)
    end

    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to belong_to(:auditable).polymorphic }
    it { is_expected.to belong_to(:user).class_name('User') }
  end

  describe 'scope methods' do
    let(:container) { create(:cde_container) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    describe '.for_container' do
      it 'returns events for the container and its revisions' do
        create(:cde_audit_event, auditable: container, user: user1)
        revision = container.revisions.first
        create(:cde_audit_event, auditable: revision, user: user2)

        events = Cde::AuditEvent.for_container(container)
        expect(events.count).to eq(2)
      end
    end

    describe '.recent' do
      it 'returns events from the last N hours' do
        create(:cde_audit_event, created_at: 1.hour.ago)
        create(:cde_audit_event, created_at: 2.days.ago)

        recent = Cde::AuditEvent.recent(hours: 24)
        expect(recent.count).to eq(1)
      end
    end

    describe '.by_action' do
      it 'filters by action' do
        create(:cde_audit_event, action: 'container.created')
        create(:cde_audit_event, action: 'container.shared')

        created = Cde::AuditEvent.by_action('container.created')
        expect(created.count).to eq(1)
      end
    end

    describe '.by_user' do
      it 'filters by user' do
        create(:cde_audit_event, user: user1)
        create(:cde_audit_event, user: user2)

        user_events = Cde::AuditEvent.by_user(user1)
        expect(user_events.count).to eq(1)
      end
    end
  end
end
