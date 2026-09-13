# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bim::Security::AuditService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { described_class.new(user: user, project: project) }

  before do
    # Mock RequestStore for IP and user agent tracking
    allow(RequestStore).to receive(:store).and_return({
      current_user_ip: '192.168.1.100',
      current_user_agent: 'TestAgent/1.0',
      request_id: 'test-request-123'
    })
  end

  describe '#log_action' do
    it 'creates an audit log entry' do
      expect do
        service.log_action(
          action: :model_upload,
          details: { file_name: 'test.ifc' }
        )
      end.to change(Bim::AuditLog, :count).by(1)
    end

    it 'logs with user and project' do
      log = service.log_action(
        action: :model_upload,
        details: { file_name: 'test.ifc' }
      )

      expect(log.user).to eq(user)
      expect(log.project).to eq(project)
    end

    it 'captures IP address from RequestStore' do
      log = service.log_action(
        action: :model_upload,
        details: { file_name: 'test.ifc' }
      )

      expect(log.ip_address.to_s).to eq('192.168.1.100')
    end

    it 'captures user agent from RequestStore' do
      log = service.log_action(
        action: :model_upload,
        details: { file_name: 'test.ifc' }
      )

      expect(log.user_agent).to eq('TestAgent/1.0')
    end

    it 'captures request ID from RequestStore' do
      log = service.log_action(
        action: :model_upload,
        details: { file_name: 'test.ifc' }
      )

      expect(log.request_id).to eq('test-request-123')
    end

    it 'stores custom details' do
      log = service.log_action(
        action: :clash_detection_run,
        details: { clash_count: 15, tolerance: 0.01 }
      )

      expect(log.details['clash_count']).to eq(15)
      expect(log.details['tolerance']).to eq(0.01)
    end

    it 'works when RequestStore is not available' do
      allow(service).to receive(:defined?).with(RequestStore).and_return(false)

      log = service.log_action(
        action: :model_upload,
        details: { file_name: 'test.ifc' }
      )

      expect(log.ip_address).to be_nil
      expect(log.user_agent).to be_nil
    end
  end

  describe '#generate_security_report' do
    before do
      # Create various audit logs
      3.times { create(:bim_audit_log, :model_upload, project: project) }
      2.times { create(:bim_audit_log, :clash_detection_run, project: project) }
      create(:bim_audit_log, :permission_changed, project: project)
      create(:bim_audit_log, :api_token_created, project: project)

      # Create old logs that should be excluded
      create(:bim_audit_log, :old, project: project)
    end

    it 'generates a comprehensive security report' do
      report = service.generate_security_report(since: 30.days.ago)

      expect(report).to include(
        :project_id,
        :project_name,
        :report_period,
        :activity_summary,
        :top_users,
        :security_sensitive_actions,
        :total_actions
      )
    end

    it 'includes project information' do
      report = service.generate_security_report

      expect(report[:project_id]).to eq(project.id)
      expect(report[:project_name]).to eq(project.name)
    end

    it 'includes report period' do
      since = 15.days.ago
      report = service.generate_security_report(since: since)

      expect(report[:report_period][:start]).to be_within(1.second).of(since)
      expect(report[:report_period][:end]).to be_within(1.second).of(Time.current)
    end

    it 'includes activity summary' do
      report = service.generate_security_report(since: 30.days.ago)

      expect(report[:activity_summary]['model_upload']).to eq(3)
      expect(report[:activity_summary]['clash_detection_run']).to eq(2)
    end

    it 'includes top users' do
      report = service.generate_security_report(since: 30.days.ago)

      expect(report[:top_users]).to be_an(Array)
    end

    it 'includes security sensitive actions' do
      report = service.generate_security_report(since: 30.days.ago)

      sensitive_actions = report[:security_sensitive_actions]
      expect(sensitive_actions.length).to eq(2) # permission_changed + api_token_created
    end

    it 'includes total action count' do
      report = service.generate_security_report(since: 30.days.ago)

      expect(report[:total_actions]).to eq(6) # Excludes old logs
    end

    it 'filters by time period' do
      report = service.generate_security_report(since: 1.week.ago)

      # Should only count recent logs, not the old one
      expect(report[:total_actions]).to eq(6)
    end
  end

  describe '#export_to_csv' do
    before do
      create(:bim_audit_log, :model_upload, project: project)
      create(:bim_audit_log, :clash_detection_run, project: project)
    end

    it 'exports audit logs to CSV format' do
      csv = service.export_to_csv(since: 30.days.ago)

      expect(csv).to be_a(String)
      expect(csv).to include('ID,Timestamp,User,Project,Action,IP Address,Details')
    end

    it 'includes all recent logs' do
      csv = service.export_to_csv(since: 30.days.ago)

      expect(csv).to include('model_upload')
      expect(csv).to include('clash_detection_run')
    end

    it 'filters by time period' do
      old_log = create(:bim_audit_log, :old, project: project)

      csv = service.export_to_csv(since: 1.week.ago)

      # Should not include old log
      expect(csv.scan(/\n/).count).to eq(3) # Header + 2 recent logs
    end

    it 'orders logs by most recent first' do
      csv = service.export_to_csv(since: 30.days.ago)
      lines = csv.split("\n")

      # Most recent should be first (after header)
      expect(lines[1]).to include('clash_detection_run')
    end
  end

  describe 'private methods' do
    describe '#security_sensitive_actions' do
      before do
        create(:bim_audit_log, :model_upload, project: project)
        create(:bim_audit_log, :permission_changed, project: project)
        create(:bim_audit_log, :api_token_revoked, project: project)
        create(:bim_audit_log, :data_exported, project: project)
      end

      it 'returns only security sensitive actions' do
        sensitive = service.send(:security_sensitive_actions, 30.days.ago)

        # Should include 3 security-sensitive actions
        expect(sensitive.length).to eq(3)
        expect(sensitive.map { |a| a[:action_type] }).to contain_exactly(
          'permission_changed',
          'api_token_revoked',
          'data_exported'
        )
      end

      it 'excludes non-sensitive actions' do
        sensitive = service.send(:security_sensitive_actions, 30.days.ago)

        action_types = sensitive.map { |a| a[:action_type] }
        expect(action_types).not_to include('model_upload')
      end
    end
  end
end
