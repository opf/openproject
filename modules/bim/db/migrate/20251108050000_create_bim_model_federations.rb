# frozen_string_literal: true

class CreateBimModelFederations < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_model_federations do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.text :description

      # Coordinate system configuration
      # base_point: Project origin in world coordinates
      # rotation: Rotation angles in degrees (x, y, z)
      # units: Measurement units for the federation
      t.jsonb :base_point, null: false, default: { x: 0, y: 0, z: 0 }
      t.jsonb :rotation, null: false, default: { x: 0, y: 0, z: 0 }
      t.string :units, limit: 20, default: 'meters'

      t.timestamps null: false
    end

    add_index :bim_model_federations, :project_id, name: 'idx_federations_project'
    add_index :bim_model_federations, :name, name: 'idx_federations_name'
    add_index :bim_model_federations, :created_at, name: 'idx_federations_created_at'
  end
end
