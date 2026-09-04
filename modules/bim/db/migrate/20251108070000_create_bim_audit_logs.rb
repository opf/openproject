# frozen_string_literal: true

class CreateBimAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_audit_logs do |t|
      t.references :user,
                   foreign_key: { to_table: :users, on_delete: :set_null },
                   index: true
      t.references :project,
                   null: false,
                   foreign_key: { to_table: :projects, on_delete: :cascade },
                   index: true

      # Action type enum:
      # 0=model_upload, 1=model_delete, 2=clash_detection_run,
      # 3=baseline_created, 4=baseline_deleted, 5=federation_created,
      # 6=comparison_run, 7=permission_changed, 8=api_key_created,
      # 9=api_key_revoked, 10=export_data
      t.integer :action_type, null: false

      # JSONB for action-specific details
      # e.g., { model_id: 123, file_size: 5242880, file_name: 'building.ifc' }
      t.jsonb :details, default: {}, null: false

      # IP address of the user performing the action
      t.inet :ip_address

      # User agent for API requests
      t.string :user_agent, limit: 500

      # Request ID for correlation
      t.string :request_id, limit: 100

      t.timestamp :created_at, null: false
    end

    # Indexes for efficient queries
    add_index :bim_audit_logs, :user_id, name: 'idx_audit_logs_user'
    add_index :bim_audit_logs, :project_id, name: 'idx_audit_logs_project'
    add_index :bim_audit_logs, :action_type, name: 'idx_audit_logs_action'
    add_index :bim_audit_logs, :created_at, name: 'idx_audit_logs_created'
    add_index :bim_audit_logs, :ip_address, name: 'idx_audit_logs_ip'
    add_index :bim_audit_logs, :request_id, name: 'idx_audit_logs_request'

    # GIN index for JSONB details column
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE INDEX idx_audit_logs_details ON bim_audit_logs USING GIN (details);
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP INDEX IF EXISTS idx_audit_logs_details;
        SQL
      end
    end

    # Partitioning hint: Consider partitioning by created_at for large datasets
    # CREATE TABLE bim_audit_logs_2025_01 PARTITION OF bim_audit_logs
    #   FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
  end
end
