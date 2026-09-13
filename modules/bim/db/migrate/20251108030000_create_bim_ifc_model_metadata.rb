# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateBimIfcModelMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_ifc_model_metadata do |t|
      t.references :ifc_model, null: false, foreign_key: { to_table: :bim_ifc_models, on_delete: :cascade }, index: { unique: true }

      # IFC File Information
      t.string :ifc_version, limit: 20 # 'IFC2x3', 'IFC4', 'IFC4x3', etc.
      t.string :file_schema, limit: 50 # 'IFC4_ADD2', etc.
      t.string :file_checksum, limit: 64 # SHA256 for deduplication
      t.integer :entity_count
      t.integer :geometry_count

      # Spatial Structure (JSONB)
      # Structure: { "IfcProject": { "name": "...", "children": [ ... ] } }
      t.jsonb :spatial_structure, default: {}, null: false

      # Property Sets (JSONB)
      # Structure: { "Pset_WallCommon": { "properties": { ... } }, ... }
      t.jsonb :property_sets, default: {}, null: false

      # Quantities (JSONB)
      # Structure: { "total_area": 5000, "total_volume": 15000, "by_type": { ... } }
      t.jsonb :quantities, default: {}, null: false

      # Classifications (JSONB)
      # Structure: { "Uniclass": [...], "OmniClass": [...] }
      t.jsonb :classifications, default: {}, null: false

      # Materials (JSONB)
      # Structure: { "materials": [ { "name": "Concrete", "layers": [...] } ] }
      t.jsonb :materials, default: {}, null: false

      # Types/Families (JSONB)
      # Structure: { "IfcWallType": { "count": 10, "types": [...] } }
      t.jsonb :types, default: {}, null: false

      # Validation Results (JSONB)
      # Structure: { "warnings": [...], "errors": [], "complexity_score": 0.7 }
      t.jsonb :validation_result, default: {}, null: false

      # Performance Metrics
      t.integer :estimated_conversion_time # seconds
      t.integer :actual_conversion_time # seconds

      t.timestamps null: false
    end

    # Indexes for efficient queries
    add_index :bim_ifc_model_metadata, :ifc_version, name: 'index_ifc_metadata_on_version'
    add_index :bim_ifc_model_metadata, :file_checksum, name: 'index_ifc_metadata_on_checksum'
    add_index :bim_ifc_model_metadata, :entity_count, name: 'index_ifc_metadata_on_entity_count'

    # GIN indexes for JSONB columns for fast queries
    add_index :bim_ifc_model_metadata, :spatial_structure, using: :gin, name: 'index_ifc_metadata_on_spatial_structure'
    add_index :bim_ifc_model_metadata, :property_sets, using: :gin, name: 'index_ifc_metadata_on_property_sets'
    add_index :bim_ifc_model_metadata, :quantities, using: :gin, name: 'index_ifc_metadata_on_quantities'
    add_index :bim_ifc_model_metadata, :classifications, using: :gin, name: 'index_ifc_metadata_on_classifications'
    add_index :bim_ifc_model_metadata, :materials, using: :gin, name: 'index_ifc_metadata_on_materials'
    add_index :bim_ifc_model_metadata, :types, using: :gin, name: 'index_ifc_metadata_on_types'
  end
end
