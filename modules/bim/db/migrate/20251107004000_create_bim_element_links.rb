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

class CreateBimElementLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_element_links do |t|
      t.references :work_package,
                   null: false,
                   foreign_key: { to_table: :work_packages, on_delete: :cascade },
                   index: true

      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :ifc_models, on_delete: :cascade },
                   index: true

      t.references :user,
                   null: true,
                   foreign_key: { to_table: :users, on_delete: :nullify },
                   index: true

      # Element identification
      t.string :element_id, null: false, limit: 50  # IFC GUID (e.g., "2O2Fr$t4X7Zf8NOew3FNr2")
      t.string :element_type, limit: 50             # IfcWall, IfcDoor, etc.
      t.string :element_name, limit: 255            # Human-readable name

      # Relationship type: affected_by, responsible_for, depends_on, observes, related_to
      t.integer :relationship_type, null: false, default: 0

      # Link status: active, completed, archived
      t.integer :status, null: false, default: 0

      # Snapshot of element properties at link time (Psets, quantities, classification, etc.)
      t.jsonb :element_properties, default: {}

      # Optional description of why this link exists
      t.text :description

      t.timestamps
    end

    # Composite indexes for common queries
    add_index :bim_element_links, [:work_package_id, :element_id], unique: true, name: 'idx_element_links_wp_element'
    add_index :bim_element_links, [:ifc_model_id, :element_id], name: 'idx_element_links_model_element'
    add_index :bim_element_links, :relationship_type
    add_index :bim_element_links, :status
    add_index :bim_element_links, :element_type
    add_index :bim_element_links, :element_properties, using: :gin

    # Check constraint for valid relationship types
    add_check_constraint :bim_element_links,
                         'relationship_type >= 0 AND relationship_type <= 4',
                         name: 'chk_valid_relationship_type'

    # Check constraint for valid statuses
    add_check_constraint :bim_element_links,
                         'status >= 0 AND status <= 2',
                         name: 'chk_valid_status'
  end
end
