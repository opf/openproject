# frozen_string_literal: true

class CreateCdeMetadata < ActiveRecord::Migration[7.0]
  def change
    create_table :cde_metadata do |t|
      t.references :container, null: false, foreign_key: { to_table: :cde_containers }, index: true
      t.references :revision, foreign_key: { to_table: :cde_revisions }, index: true
      t.integer :discipline, null: false, default: 0
      t.integer :container_type, null: false, default: 0
      t.string :originator, null: false
      t.string :classification
      t.string :status
      t.string :revision_phase
      t.string :purpose
      t.string :intended_use
      t.timestamps
    end

    add_index :cde_metadata, :discipline
    add_index :cde_metadata, :container_type
    add_index :cde_metadata, :originator
  end
end
