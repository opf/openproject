# frozen_string_literal: true

class CreateCdeContainers < ActiveRecord::Migration[7.0]
  def change
    create_table :cde_containers do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :owner, foreign_key: { to_table: :users }, index: true
      t.string :identifier, null: false
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.string :original_filename
      t.timestamps
    end

    add_index :cde_containers, [:project_id, :identifier], unique: true
    add_index :cde_containers, :status
    add_index :cde_containers, :created_at
  end
end
