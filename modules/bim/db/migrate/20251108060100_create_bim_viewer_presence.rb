# frozen_string_literal: true

class CreateBimViewerPresence < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_viewer_presence do |t|
      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade },
                   index: true
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :users, on_delete: :cascade },
                   index: true

      t.datetime :last_seen_at, null: false

      # Current camera position in the viewer
      # camera_position: { eye: [x, y, z], look: [x, y, z], up: [x, y, z] }
      t.jsonb :camera_position

      t.timestamps null: false
    end

    # Composite unique constraint: each user has one presence record per model
    add_index :bim_viewer_presence,
              [:ifc_model_id, :user_id],
              unique: true,
              name: 'idx_unique_viewer_presence'

    add_index :bim_viewer_presence, :last_seen_at, name: 'idx_viewer_presence_last_seen'
  end
end
