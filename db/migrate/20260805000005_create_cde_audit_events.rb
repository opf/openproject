# frozen_string_literal: true

class CreateCdeAuditEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :cde_audit_events do |t|
      t.references :auditable, polymorphic: true, null: false, index: true
      t.references :user, foreign_key: { to_table: :users }, null: false, index: true
      t.string :action, null: false
      t.string :event_type, null: false
      t.jsonb :old_state
      t.jsonb :new_state
      t.text :reason
      t.timestamps
    end

    add_index :cde_audit_events, [:auditable_type, :auditable_id, :created_at]
    add_index :cde_audit_events, :user_id
    add_index :cde_audit_events, :action
    add_index :cde_audit_events, :created_at
  end
end
