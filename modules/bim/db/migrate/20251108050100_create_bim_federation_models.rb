# frozen_string_literal: true

class CreateBimFederationModels < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_federation_models do |t|
      t.references :model_federation,
                   null: false,
                   foreign_key: { to_table: :bim_model_federations, on_delete: :cascade },
                   index: true
      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade },
                   index: true

      # Discipline classification
      # 0=architectural, 1=structural, 2=mechanical, 3=electrical
      # 4=plumbing, 5=civil, 6=landscape, 99=other
      t.integer :discipline, default: 99, null: false

      # Transformation matrix for spatial alignment
      # translation: [x, y, z] offset from base point
      # rotation: [rx, ry, rz] rotation angles in degrees
      # scale: [sx, sy, sz] scale factors (typically [1,1,1])
      t.jsonb :transform, null: false, default: {
        translation: [0, 0, 0],
        rotation: [0, 0, 0],
        scale: [1, 1, 1]
      }

      # Display properties
      t.integer :display_order, default: 0, null: false
      t.boolean :visible, default: true, null: false
      t.string :color, limit: 7 # Hex color code for discipline (e.g., '#FF5733')
      t.decimal :opacity, precision: 3, scale: 2, default: 1.0 # 0.00 to 1.00

      t.timestamps null: false
    end

    # Composite unique constraint: each model can only be in a federation once
    add_index :bim_federation_models,
              [:model_federation_id, :ifc_model_id],
              unique: true,
              name: 'idx_unique_federation_model'

    add_index :bim_federation_models, :discipline, name: 'idx_federation_models_discipline'
    add_index :bim_federation_models, :display_order, name: 'idx_federation_models_display_order'
    add_index :bim_federation_models, :visible, name: 'idx_federation_models_visible'

    # Check constraints
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE bim_federation_models
          ADD CONSTRAINT check_discipline_value
          CHECK (discipline >= 0 AND discipline <= 99);

          ALTER TABLE bim_federation_models
          ADD CONSTRAINT check_opacity_range
          CHECK (opacity >= 0.0 AND opacity <= 1.0);
        SQL
      end

      dir.down do
        execute <<-SQL
          ALTER TABLE bim_federation_models DROP CONSTRAINT IF EXISTS check_discipline_value;
          ALTER TABLE bim_federation_models DROP CONSTRAINT IF EXISTS check_opacity_range;
        SQL
      end
    end
  end
end
