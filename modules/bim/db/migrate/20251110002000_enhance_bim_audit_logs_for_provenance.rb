# frozen_string_literal: true

class EnhanceBimAuditLogsForProvenance < ActiveRecord::Migration[7.1]
  def change
    # Add versioning and provenance fields
    add_column :bim_audit_logs, :entity_type, :string, limit: 100
    add_column :bim_audit_logs, :entity_id, :bigint
    add_column :bim_audit_logs, :entity_version, :integer, default: 1
    add_column :bim_audit_logs, :previous_version, :integer
    add_column :bim_audit_logs, :changes, :jsonb, default: {}
    add_column :bim_audit_logs, :snapshot_before, :jsonb
    add_column :bim_audit_logs, :snapshot_after, :jsonb
    add_column :bim_audit_logs, :checksum, :string, limit: 64
    add_column :bim_audit_logs, :parent_log_id, :bigint
    add_column :bim_audit_logs, :tags, :string, array: true, default: []
    add_column :bim_audit_logs, :severity, :integer, default: 0
    add_column :bim_audit_logs, :reversible, :boolean, default: false
    add_column :bim_audit_logs, :reversed_by_id, :bigint
    add_column :bim_audit_logs, :reversed_at, :datetime

    # Add indexes for new columns
    add_index :bim_audit_logs, [:entity_type, :entity_id], name: 'idx_audit_logs_entity'
    add_index :bim_audit_logs, :entity_version, name: 'idx_audit_logs_version'
    add_index :bim_audit_logs, :checksum, name: 'idx_audit_logs_checksum'
    add_index :bim_audit_logs, :parent_log_id, name: 'idx_audit_logs_parent'
    add_index :bim_audit_logs, :tags, using: :gin, name: 'idx_audit_logs_tags'
    add_index :bim_audit_logs, :severity, name: 'idx_audit_logs_severity'
    add_index :bim_audit_logs, :changes, using: :gin, name: 'idx_audit_logs_changes'
    add_index :bim_audit_logs, :snapshot_before, using: :gin, name: 'idx_audit_logs_snapshot_before'
    add_index :bim_audit_logs, :snapshot_after, using: :gin, name: 'idx_audit_logs_snapshot_after'

    # Add foreign key for reversed_by
    add_foreign_key :bim_audit_logs, :users, column: :reversed_by_id, on_delete: :nullify

    # Add foreign key for parent_log (for compound transactions)
    add_foreign_key :bim_audit_logs, :bim_audit_logs, column: :parent_log_id, on_delete: :nullify
  end
end
