# frozen_string_literal: true

module Bim
  class AuditLog < ApplicationRecord
    self.table_name = 'bim_audit_logs'

    # Configuration constants
    DEFAULT_ACTIVITY_PERIOD = 30.days
    DEFAULT_TOP_USERS_LIMIT = 10
    DEFAULT_RETENTION_PERIOD = 2.years
    CSV_HEADERS = ['ID', 'Timestamp', 'User', 'Project', 'Entity', 'Action', 'Severity', 'IP Address', 'Changes'].freeze
    SECURITY_SENSITIVE_ACTIONS = %i[
      permission_changed
      api_key_created
      api_key_revoked
      export_data
      model_delete
      federation_deleted
    ].freeze

    # Associations
    belongs_to :user, optional: true # Optional because user might be deleted
    belongs_to :project
    belongs_to :parent_log, class_name: 'Bim::AuditLog', optional: true
    belongs_to :reversed_by, class_name: 'User', optional: true
    has_many :child_logs, class_name: 'Bim::AuditLog', foreign_key: :parent_log_id, dependent: :nullify

    # Action type enum
    enum action_type: {
      # Model operations (0-9)
      model_upload: 0,
      model_delete: 1,
      model_update: 2,
      model_conversion_started: 3,
      model_conversion_completed: 4,
      model_conversion_failed: 5,
      model_metadata_refreshed: 6,

      # Clash operations (10-19)
      clash_detection_run: 10,
      clash_resolved: 11,
      clash_approved: 12,
      clash_assigned: 13,
      clash_reopened: 14,

      # Baseline operations (20-29)
      baseline_created: 20,
      baseline_deleted: 21,
      baseline_set_current: 22,
      baseline_snapshot: 23,

      # Federation operations (30-39)
      federation_created: 30,
      federation_updated: 31,
      federation_deleted: 32,
      federation_aligned: 33,

      # Comparison operations (40-49)
      comparison_run: 40,
      comparison_approved: 41,
      comparison_rejected: 42,

      # Issue operations (50-59)
      issue_created: 50,
      issue_updated: 51,
      issue_deleted: 52,
      issue_commented: 53,
      issue_mentioned: 54,
      issue_assigned: 55,

      # Workflow operations (60-69)
      workflow_initialized: 60,
      workflow_transitioned: 61,
      workflow_completed: 62,
      workflow_reset: 63,
      workflow_removed: 64,

      # Element operations (70-79)
      element_linked: 70,
      element_unlinked: 71,
      element_updated: 72,
      element_properties_refreshed: 73,
      element_progress_updated: 74,

      # Security operations (80-89)
      permission_changed: 80,
      api_key_created: 81,
      api_key_revoked: 82,
      user_login: 83,
      user_logout: 84,

      # Data operations (90-99)
      export_data: 90,
      import_data: 91,
      bulk_operation: 92,
      bulk_update: 93,
      bulk_delete: 94,

      # System operations (100-109)
      cache_cleared: 100,
      cache_warmed: 101,
      background_job_started: 102,
      background_job_completed: 103,
      background_job_failed: 104,

      # Viewer operations (110-119)
      viewer_presence_updated: 110,
      saved_view_created: 111,
      saved_view_updated: 112,
      measurement_created: 113,
      annotation_created: 114
    }

    # Severity levels
    enum severity: {
      info: 0,
      low: 1,
      medium: 2,
      high: 3,
      critical: 4
    }, _prefix: :severity

    # Validations
    validates :action_type, presence: true
    validates :project, presence: true
    validate :validate_checksum_if_present
    validate :validate_entity_consistency

    # Callbacks
    before_create :calculate_entity_version
    before_create :generate_checksum
    after_create :update_entity_version_cache

    # Scopes
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :for_action, ->(action) { where(action_type: action) }
    scope :for_entity, ->(entity_type, entity_id = nil) {
      scope = where(entity_type: entity_type)
      scope = scope.where(entity_id: entity_id) if entity_id
      scope
    }
    scope :with_changes, -> { where.not(changes: {}) }
    scope :with_snapshots, -> { where.not(snapshot_before: nil).or(where.not(snapshot_after: nil)) }
    scope :reversible, -> { where(reversible: true) }
    scope :not_reversed, -> { where(reversed_at: nil) }
    scope :reversed, -> { where.not(reversed_at: nil) }
    scope :recent, -> { order(created_at: :desc) }
    scope :chronological, -> { order(created_at: :asc) }
    scope :since, ->(time) { where('created_at >= ?', time) }
    scope :before, ->(time) { where('created_at <= ?', time) }
    scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
    scope :by_severity, ->(severity_level) { where(severity: severity_level) }
    scope :security_sensitive, -> { where(action_type: SECURITY_SENSITIVE_ACTIONS) }
    scope :tagged_with, ->(tag) { where('? = ANY(tags)', tag) }
    scope :root_logs, -> { where(parent_log_id: nil) }

    # Class methods

    # Enhanced logging with versioning and snapshots
    def self.log_with_snapshot(
      user:,
      project:,
      action:,
      entity: nil,
      entity_type: nil,
      entity_id: nil,
      details: {},
      changes: {},
      snapshot_before: nil,
      snapshot_after: nil,
      severity: :info,
      reversible: false,
      tags: [],
      ip_address: nil,
      user_agent: nil,
      request_id: nil,
      parent_log: nil
    )
      # Extract entity info from object if provided
      if entity
        entity_type ||= entity.class.name
        entity_id ||= entity.id
      end

      create!(
        user: user,
        project: project,
        action_type: action,
        entity_type: entity_type,
        entity_id: entity_id,
        details: details,
        changes: changes,
        snapshot_before: snapshot_before,
        snapshot_after: snapshot_after,
        severity: severity,
        reversible: reversible,
        tags: tags,
        ip_address: ip_address || current_ip_address,
        user_agent: user_agent || current_user_agent,
        request_id: request_id || current_request_id,
        parent_log: parent_log
      )
    end

    # Simplified logging (backward compatible)
    def self.log(user:, project:, action:, details: {}, ip_address: nil, user_agent: nil, request_id: nil)
      log_with_snapshot(
        user: user,
        project: project,
        action: action,
        details: details,
        ip_address: ip_address,
        user_agent: user_agent,
        request_id: request_id
      )
    end

    # Get activity summary for a project
    def self.activity_summary(project_id, since: DEFAULT_ACTIVITY_PERIOD.ago)
      for_project(project_id)
        .since(since)
        .group(:action_type)
        .count
    end

    # Get top users by activity
    def self.top_users(project_id, limit: DEFAULT_TOP_USERS_LIMIT, since: DEFAULT_ACTIVITY_PERIOD.ago)
      for_project(project_id)
        .since(since)
        .where.not(user_id: nil)
        .group(:user_id)
        .count
        .sort_by { |_, count| -count }
        .first(limit)
        .map { |user_id, count| { user_id: user_id, action_count: count } }
    end

    # Get entity change history
    def self.entity_history(entity_type, entity_id)
      for_entity(entity_type, entity_id)
        .chronological
        .includes(:user, :reversed_by)
    end

    # Get entity version timeline
    def self.entity_versions(entity_type, entity_id)
      for_entity(entity_type, entity_id)
        .where.not(entity_version: nil)
        .order(entity_version: :asc)
    end

    # Get changes between versions
    def self.diff_versions(entity_type, entity_id, from_version, to_version)
      logs = for_entity(entity_type, entity_id)
             .where('entity_version > ? AND entity_version <= ?', from_version, to_version)
             .chronological

      {
        entity_type: entity_type,
        entity_id: entity_id,
        from_version: from_version,
        to_version: to_version,
        changes: logs.map(&:changes).reduce({}, :merge),
        log_count: logs.count
      }
    end

    # Export audit logs to CSV
    def self.to_csv(logs)
      require 'csv'

      CSV.generate do |csv|
        csv << CSV_HEADERS

        logs.each do |log|
          csv << [
            log.id,
            log.created_at.iso8601,
            log.user&.name || 'N/A',
            log.project.name,
            log.entity_display,
            log.action_type,
            log.severity,
            log.ip_address,
            log.changes.to_json
          ]
        end
      end
    end

    # Export audit logs to JSON
    def self.to_json_export(logs)
      {
        exported_at: Time.current.iso8601,
        count: logs.count,
        logs: logs.map(&:to_hash)
      }.to_json
    end

    # Cleanup old audit logs (call from scheduled job)
    def self.cleanup_old_logs(older_than: DEFAULT_RETENTION_PERIOD.ago)
      where('created_at < ?', older_than).delete_all
    end

    # Verify log integrity
    def self.verify_integrity(logs)
      logs.map do |log|
        {
          id: log.id,
          valid: log.verify_checksum,
          checksum: log.checksum
        }
      end
    end

    # Instance methods

    # Get human-readable action description
    def action_description
      case action_type.to_sym
      when :model_upload
        "Uploaded model: #{details['file_name']}"
      when :model_delete
        "Deleted model ID: #{details['model_id']}"
      when :model_conversion_completed
        "Completed conversion for model: #{details['model_id']}"
      when :clash_detection_run
        "Ran clash detection: #{details['clash_test_name']}"
      when :clash_resolved
        "Resolved clash ID: #{entity_id}"
      when :workflow_transitioned
        "Workflow transition: #{details['from_state']} → #{details['to_state']}"
      when :issue_created
        "Created issue: #{details['issue_title']}"
      when :element_linked
        "Linked element #{details['element_id']} to work package"
      when :permission_changed
        "Changed permissions for user: #{details['target_user']}"
      when :api_key_created
        "Created API key: #{details['token_name']}"
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
      SECURITY_SENSITIVE_ACTIONS.include?(action_type.to_sym)
    end

    # Get entity display string
    def entity_display
      return 'N/A' unless entity_type && entity_id

      "#{entity_type}##{entity_id}"
    end

    # Get changes summary
    def changes_summary
      return 'No changes' if changes.blank?

      changes.map { |key, value_pair|
        if value_pair.is_a?(Array) && value_pair.length == 2
          "#{key}: #{value_pair[0]} → #{value_pair[1]}"
        else
          "#{key}: #{value_pair}"
        end
      }.join(', ')
    end

    # Check if this log has snapshots
    def has_snapshots?
      snapshot_before.present? || snapshot_after.present?
    end

    # Get snapshot diff
    def snapshot_diff
      return {} unless has_snapshots?

      before_keys = (snapshot_before&.keys || []).to_set
      after_keys = (snapshot_after&.keys || []).to_set
      all_keys = before_keys + after_keys

      diff = {}
      all_keys.each do |key|
        before_val = snapshot_before&.dig(key)
        after_val = snapshot_after&.dig(key)

        next if before_val == after_val

        diff[key] = {
          before: before_val,
          after: after_val,
          changed: true
        }
      end

      diff
    end

    # Verify checksum
    def verify_checksum
      return true if checksum.blank?

      calculated = calculate_checksum_value
      checksum == calculated
    end

    # Reverse this action (if reversible)
    def reverse!(user:, comment: nil)
      raise 'Log entry is not reversible' unless reversible?
      raise 'Log entry already reversed' if reversed?

      transaction do
        # Mark as reversed
        update!(
          reversed_by: user,
          reversed_at: Time.current
        )

        # Create reverse log entry
        reverse_log = self.class.create!(
          user: user,
          project: project,
          action_type: derive_reverse_action,
          entity_type: entity_type,
          entity_id: entity_id,
          details: details.merge(
            reversed_log_id: id,
            reversal_comment: comment
          ),
          snapshot_before: snapshot_after,
          snapshot_after: snapshot_before,
          severity: severity,
          parent_log: parent_log,
          tags: tags + ['reversal']
        )

        reverse_log
      end
    end

    # Check if reversed
    def reversed?
      reversed_at.present?
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
        entity: entity_display,
        entity_type: entity_type,
        entity_id: entity_id,
        entity_version: entity_version,
        action: action_type,
        action_description: action_description,
        severity: severity,
        details: details,
        changes: changes,
        changes_summary: changes_summary,
        has_snapshots: has_snapshots?,
        reversible: reversible,
        reversed: reversed?,
        reversed_at: reversed_at&.iso8601,
        tags: tags,
        ip_address: ip_address&.to_s,
        user_agent: user_agent,
        request_id: request_id,
        checksum: checksum,
        checksum_valid: verify_checksum
      }
    end

    private

    def calculate_entity_version
      return unless entity_type && entity_id

      # Get the highest version for this entity
      last_log = self.class
                     .for_entity(entity_type, entity_id)
                     .where.not(id: id)
                     .order(entity_version: :desc)
                     .first

      self.previous_version = last_log&.entity_version
      self.entity_version = (last_log&.entity_version || 0) + 1
    end

    def generate_checksum
      self.checksum = calculate_checksum_value
    end

    def calculate_checksum_value
      # Generate SHA256 checksum of log data
      data = {
        user_id: user_id,
        project_id: project_id,
        action_type: action_type,
        entity_type: entity_type,
        entity_id: entity_id,
        details: details,
        changes: changes,
        created_at: created_at&.to_i
      }.to_json

      Digest::SHA256.hexdigest(data)
    end

    def update_entity_version_cache
      # Could cache version info in Redis for fast lookups
      # Rails.cache.write("audit:#{entity_type}:#{entity_id}:version", entity_version)
    end

    def derive_reverse_action
      # Map action types to their reverse equivalents
      case action_type.to_sym
      when :model_upload then :model_delete
      when :model_delete then :model_upload
      when :element_linked then :element_unlinked
      when :element_unlinked then :element_linked
      when :workflow_initialized then :workflow_removed
      else
        "reverse_#{action_type}".to_sym
      end
    end

    def validate_checksum_if_present
      if checksum.present? && !verify_checksum
        errors.add(:checksum, 'is invalid')
      end
    end

    def validate_entity_consistency
      if entity_type.present? ^ entity_id.present?
        errors.add(:base, 'Both entity_type and entity_id must be present or both must be nil')
      end
    end

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
