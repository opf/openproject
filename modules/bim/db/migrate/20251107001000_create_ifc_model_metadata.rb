# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

class CreateIfcModelMetadata < ActiveRecord::Migration[7.1]
  def change
    create_table :ifc_model_metadata do |t|
      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :ifc_models, on_delete: :cascade },
                   index: { unique: true }

      t.string :ifc_version, limit: 20 # 'IFC2x3', 'IFC4', 'IFC4x3'
      t.integer :entity_count
      t.integer :geometry_count
      t.jsonb :spatial_structure, default: {} # Building → Storey → Space tree
      t.jsonb :property_sets, default: {} # All extracted Psets
      t.jsonb :quantities, default: {} # Areas, volumes, etc. (QTO)
      t.jsonb :classifications, default: {} # Uniclass, OmniClass, etc.
      t.jsonb :materials, default: {}
      t.jsonb :element_index, default: {} # Fast element property lookup
      t.jsonb :geometry_index, default: {} # Bounding boxes for all elements
      t.string :file_checksum, limit: 64 # SHA256 for deduplication

      t.timestamps
    end

    add_index :ifc_model_metadata, :file_checksum
    add_index :ifc_model_metadata, :ifc_version
    add_index :ifc_model_metadata, :element_index, using: :gin
    add_index :ifc_model_metadata, :geometry_index, using: :gin
  end
end
