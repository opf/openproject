# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::AuditLog, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:audit_log) { create(:bim_audit_log, user: user, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:action_type) }
    it { is_expected.to validate_presence_of(:project) }

    it 'validates action_type is in valid list' do
      expect { create(:bim_audit_log, action_type: :invalid_action) }.to raise_error(ArgumentError)
    end
  end

  describe 'enums' do
    it 'defines action_type enum' do
      expect(described_class.action_types.keys).to include(
        'model_upload',
        'clash_detection_run',
        'baseline_created',
        'comparison_created',
        'api_token_created',
        'api_token_revoked',
        'permission_changed',
        'data_exported',
        'federation_created',
        'dashboard_created',
        'security_review'
      )
    end
  end

  describe 'scopes' do
    let!(:log1) { create(:bim_audit_log, project: project, action_type: :model_upload) }
    let!(:log2) { create(:bim_audit_log, action_type: :clash_detection_run) }
    let!(:log3) { create(:bim_audit_log, user: user) }

    describe '.for_project' do
      it 'returns logs for specified project' do
        expect(described_class.for_project(project.id)).to include(log1)
        expect(described_class.for_project(project.id)).not_to include(log2)
      end
    end

    describe '.for_user' do
      it 'returns logs for specified user' do
        expect(described_class.for_user(user.id)).to include(log3)
      end
    end

    describe '.for_action' do
      it 'returns logs for specified action type' do
        expect(described_class.for_action(:model_upload)).to include(log1)
        expect(described_class.for_action(:model_upload)).not_to include(log2)
      end
    end

    describe '.since' do
      it 'returns logs created after specified time' do
        log1.update(created_at: 2.days.ago)
        log2.update(created_at: 5.days.ago)

        expect(described_class.since(3.days.ago)).to include(log1)
        expect(described_class.since(3.days.ago)).not_to include(log2)
      end
    end

    describe '.recent' do
      it 'orders logs by created_at descending' do
        log1.update(created_at: 2.days.ago)
        log2.update(created_at: 1.day.ago)

        expect(described_class.recent.first).to eq(log2)
      end
    end
  end

  describe '.log' do
    it 'creates a new audit log entry' do
      expect do
        described_class.log(
          user: user,
          project: project,
          action: :model_upload,
          details: { file_name: 'test.ifc' }
        )
      end.to change(described_class, :count).by(1)
    end

    it 'stores IP address when provided' do
      log = described_class.log(
        user: user,
        project: project,
        action: :model_upload,
        ip_address: '192.168.1.100'
      )

      expect(log.ip_address.to_s).to eq('192.168.1.100')
    end

    it 'stores user agent when provided' do
      log = described_class.log(
        user: user,
        project: project,
        action: :model_upload,
        user_agent: 'TestAgent/1.0'
      )

      expect(log.user_agent).to eq('TestAgent/1.0')
    end

    it 'allows nil user for system actions' do
      log = described_class.log(
        user: nil,
        project: project,
        action: :security_review
      )

      expect(log.user).to be_nil
    end
  end

  describe '.activity_summary' do
    before do
      create(:bim_audit_log, :model_upload, project: project)
      create(:bim_audit_log, :model_upload, project: project)
      create(:bim_audit_log, :clash_detection_run, project: project)
    end

    it 'returns count grouped by action type' do
      summary = described_class.activity_summary(project.id)

      expect(summary['model_upload']).to eq(2)
      expect(summary['clash_detection_run']).to eq(1)
    end

    it 'filters by time period' do
      old_log = create(:bim_audit_log, :old, project: project)

      summary = described_class.activity_summary(project.id, since: 1.week.ago)

      expect(summary.values.sum).to eq(3) # Only recent logs
    end
  end

  describe '.top_users' do
    before do
      user1 = create(:user)
      user2 = create(:user)

      3.times { create(:bim_audit_log, user: user1, project: project) }
      2.times { create(:bim_audit_log, user: user2, project: project) }
      create(:bim_audit_log, user: user, project: project)
    end

    it 'returns users with most activity' do
      top_users = described_class.top_users(project.id, limit: 2)

      expect(top_users.length).to eq(2)
      expect(top_users.first[:count]).to eq(3)
    end
  end

  describe '.to_csv' do
    let!(:logs) do
      [
        create(:bim_audit_log, user: user, project: project, action_type: :model_upload),
        create(:bim_audit_log, user: user, project: project, action_type: :clash_detection_run)
      ]
    end

    it 'exports logs to CSV format' do
      csv = described_class.to_csv(logs)

      expect(csv).to include('ID,Timestamp,User,Project,Action,IP Address,Details')
      expect(csv).to include('model_upload')
      expect(csv).to include('clash_detection_run')
      expect(csv).to include(project.name)
    end

    it 'handles nil user' do
      logs.first.update(user: nil)
      csv = described_class.to_csv(logs)

      expect(csv).to include('N/A')
    end
  end

  describe '#security_sensitive?' do
    it 'returns true for permission changes' do
      log = create(:bim_audit_log, action_type: :permission_changed)
      expect(log.security_sensitive?).to be true
    end

    it 'returns true for API token operations' do
      log = create(:bim_audit_log, action_type: :api_token_created)
      expect(log.security_sensitive?).to be true
    end

    it 'returns true for data exports' do
      log = create(:bim_audit_log, action_type: :data_exported)
      expect(log.security_sensitive?).to be true
    end

    it 'returns false for normal operations' do
      log = create(:bim_audit_log, action_type: :model_upload)
      expect(log.security_sensitive?).to be false
    end
  end

  describe '#to_hash' do
    it 'exports log as hash with all attributes' do
      hash = audit_log.to_hash

      expect(hash).to include(
        :id,
        :user,
        :project,
        :action_type,
        :details,
        :ip_address,
        :user_agent,
        :created_at
      )
    end

    it 'includes user information when present' do
      hash = audit_log.to_hash

      expect(hash[:user]).to include(
        id: user.id,
        name: user.name,
        login: user.login
      )
    end

    it 'handles nil user' do
      audit_log.update(user: nil)
      hash = audit_log.to_hash

      expect(hash[:user]).to be_nil
    end

    it 'formats timestamps as ISO8601' do
      hash = audit_log.to_hash

      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end

  describe '#formatted_action' do
    it 'formats action type as human readable' do
      log = create(:bim_audit_log, action_type: :model_upload)
      expect(log.formatted_action).to eq('Model Upload')
    end

    it 'handles multi-word actions' do
      log = create(:bim_audit_log, action_type: :clash_detection_run)
      expect(log.formatted_action).to eq('Clash Detection Run')
    end
  end
end
