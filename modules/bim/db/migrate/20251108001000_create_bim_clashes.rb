# frozen_string_literal: true

#-- copyright
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
#++

class CreateBimClashes < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_clashes do |t|
      # IFC Model reference
      t.references :ifc_model, foreign_key: { to_table: :ifc_models }, null: false

      # Elements involved (element A and element B)
      t.string :element_a_id, limit: 50, null: false
      t.string :element_b_id, limit: 50, null: false

      # Clash classification
      t.integer :clash_type, null: false, default: 0  # hard, soft, clearance, workflow
      t.integer :severity, null: false, default: 1    # critical, major, minor
      t.integer :status, null: false, default: 0      # new, active, approved, resolved, closed

      # Clash geometry details
      t.decimal :distance, precision: 10, scale: 4     # Distance between elements (negative = overlap)
      t.decimal :overlap_volume, precision: 15, scale: 4 # Volume of intersection (for hard clashes)
      t.jsonb :clash_point, default: {}                 # 3D point where clash occurs
      t.jsonb :geometry_data, default: {}               # Additional geometry information

      # Detection metadata
      t.datetime :detected_at, null: false
      t.string :detection_run_id, limit: 100           # Batch detection identifier
      t.jsonb :detection_params, default: {}           # Parameters used for detection

      # Resolution tracking
      t.references :work_package, foreign_key: true, null: true
      t.references :assigned_to, foreign_key: { to_table: :users }, null: true
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.datetime :approved_at
      t.text :approval_comment

      t.references :resolved_by, foreign_key: { to_table: :users }, null: true
      t.datetime :resolved_at
      t.text :resolution_comment
      t.integer :resolution_type # redesign, accepted, relocated, etc.

      # Additional metadata
      t.text :description
      t.jsonb :custom_data, default: {}

      t.timestamps

      # Indexes
      t.index :element_a_id
      t.index :element_b_id
      t.index [:element_a_id, :element_b_id]
      t.index :clash_type
      t.index :severity
      t.index :status
      t.index :detected_at
      t.index :detection_run_id
      t.index :work_package_id
      t.index :assigned_to_id
      t.index :clash_point, using: :gin
      t.index :geometry_data, using: :gin
      t.index :detection_params, using: :gin
      t.index :custom_data, using: :gin

      # Composite indexes for common queries
      t.index [:ifc_model_id, :status]
      t.index [:ifc_model_id, :clash_type]
      t.index [:ifc_model_id, :severity]
      t.index [:status, :severity]

      # Unique constraint to prevent duplicate clashes
      # (same elements, regardless of order)
      t.index [:ifc_model_id, :element_a_id, :element_b_id], unique: true,
              name: 'index_bim_clashes_on_model_and_elements'
    end
  end
end
