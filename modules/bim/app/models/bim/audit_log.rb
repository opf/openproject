# frozen_string_literal: true

module Bim
  class AuditLog < ApplicationRecord
    self.table_name = 'bim_audit_logs'

    belongs_to :user, optional: true # Optional because user might be deleted
    belongs_to :project

    # Action type enum
    enum action_type: {
      model_upload: 0,
      model_delete: 1,
      clash_detection_run: 2,
      baseline_created: 3,
      baseline_deleted: 4,
      federation_created: 5,
      comparison_run: 6,
      permission_changed: 7,
      api_key_created: 8,
      api_key_revoked: 9,
      export_data: 10
    }

    validates :action_type, presence: true
    validates :project, presence: true

    # Scopes
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :for_action, ->(action) { where(action_type: action) }
    scope :recent, -> { order(created_at: :desc) }
    scope :since, ->(time) { where('created_at >= ?', time) }
    scope :before, ->(time) { where('created_at <= ?', time) }
    scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

    # Class methods

    # Log an action with all context
    def self.log(user:, project:, action:, details: {}, ip_address: nil, user_agent: nil, request_id: nil)
      create!(
        user: user,
        project: project,
        action_type: action,
        details: details,
        ip_address: ip_address || current_ip_address,
        user_agent: user_agent || current_user_agent,
        request_id: request_id || current_request_id
      )
    end

    # Get activity summary for a project
    def self.activity_summary(project_id, since: 30.days.ago)
      for_project(project_id)
        .since(since)
        .group(:action_type)
        .count
    end

    # Get top users by activity
    def self.top_users(project_id, limit: 10, since: 30.days.ago)
      for_project(project_id)
        .since(since)
        .where.not(user_id: nil)
        .group(:user_id)
        .count
        .sort_by { |_, count| -count }
        .first(limit)
        .map { |user_id, count| { user_id: user_id, action_count: count } }
    end

    # Export audit logs to CSV
    def self.to_csv(logs)
      require 'csv'

      CSV.generate do |csv|
        csv << ['ID', 'Timestamp', 'User', 'Project', 'Action', 'IP Address', 'Details']

        logs.each do |log|
          csv << [
            log.id,
            log.created_at.iso8601,
            log.user&.name || 'N/A',
            log.project.name,
            log.action_type,
            log.ip_address,
            log.details.to_json
          ]
        end
      end
    end

    # Cleanup old audit logs (call from scheduled job)
    def self.cleanup_old_logs(older_than: 2.years.ago)
      where('created_at < ?', older_than).delete_all
    end

    # Instance methods

    # Get human-readable action description
    def action_description
      case action_type.to_sym
      when :model_upload
        "Uploaded model: #{details['file_name']}"
      when :model_delete
        "Deleted model ID: #{details['model_id']}"
      when :clash_detection_run
        "Ran clash detection: #{details['clash_test_name']}"
      when :baseline_created
        "Created baseline: #{details['baseline_name']}"
      when :baseline_deleted
        "Deleted baseline ID: #{details['baseline_id']}"
      when :federation_created
        "Created federation: #{details['federation_name']}"
      when :comparison_run
        "Ran model comparison: #{details['comparison_name']}"
      when :permission_changed
        "Changed permissions for user: #{details['target_user']}"
      when :api_key_created
        "Created API key: #{details['token_name']}"
      when :api_key_revoked
        "Revoked API key: #{details['token_name']}"
      when :export_data
        "Exported data: #{details['export_type']}"
      else
        action_type.humanize
      end
    end

    # Get formatted timestamp
    def formatted_timestamp
      created_at.strftime('%Y-%m-%d %H:%M:%S %Z')
    end

    # Check if action is security-sensitive
    def security_sensitive?
      %i[permission_changed api_key_created api_key_revoked export_data].include?(action_type.to_sym)
    end

    # Export single log entry
    def to_hash
      {
        id: id,
        timestamp: created_at.iso8601,
        user: user&.name,
        user_id: user_id,
        project: project.name,
        project_id: project_id,
        action: action_type,
        action_description: action_description,
        details: details,
        ip_address: ip_address&.to_s,
        user_agent: user_agent,
        request_id: request_id
      }
    end

    private

    # Helper methods to get current context
    def self.current_ip_address
      RequestStore.store[:current_user_ip] if defined?(RequestStore)
    end

    def self.current_user_agent
      RequestStore.store[:current_user_agent] if defined?(RequestStore)
    end

    def self.current_request_id
      RequestStore.store[:request_id] if defined?(RequestStore)
    end
  end
end
