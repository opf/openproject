# frozen_string_literal: true

class CreateCdeRevisions < ActiveRecord::Migration[7.0]
  def change
    create_table :cde_revisions do |t|
      t.references :container, null: false, foreign_key: { to_table: :cde_containers }, index: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :revision_code, null: false
      t.string :title
      t.text :description
      t.integer :status, null: false, default: 0
      t.boolean :is_working, null: false, default: true
      t.string :file_path
      t.bigint :file_size
      t.string :file_mime_type
      t.datetime :published_at
      t.datetime :superseded_at
      t.timestamps
    end

    add_index :cde_revisions, [:container_id, :revision_code], unique: true
    add_index :cde_revisions, [:container_id, :is_working]
    add_index :cde_revisions, :status
  end
end
