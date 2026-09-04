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

class CreateBimElementProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_element_progresses do |t|
      # Model and baseline references
      t.references :ifc_model, foreign_key: { to_table: :ifc_models }, null: false
      t.references :baseline, foreign_key: { to_table: :bim_progress_baselines }, null: true

      # Element identification
      t.string :element_id, limit: 255, null: false
      t.string :element_type, limit: 100
      t.string :element_name, limit: 255

      # Progress status
      t.integer :status, default: 0, null: false # planned, in_progress, completed, on_hold
      t.integer :percent_complete, default: 0, null: false

      # Schedule tracking
      t.date :planned_start
      t.date :planned_finish
      t.date :actual_start
      t.date :actual_finish

      # Work package linkage
      t.references :work_package, foreign_key: true, null: true

      # Additional metadata
      t.jsonb :custom_data, default: {}
      t.text :notes

      # User tracking
      t.references :updated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps

      # Indexes
      t.index :ifc_model_id
      t.index :baseline_id
      t.index :element_id
      t.index [:ifc_model_id, :element_id]
      t.index [:ifc_model_id, :status]
      t.index [:baseline_id, :element_id]
      t.index :element_type
      t.index :status
      t.index :percent_complete
      t.index :work_package_id
      t.index :custom_data, using: :gin

      # Composite indexes for common queries
      t.index [:ifc_model_id, :percent_complete]
      t.index [:ifc_model_id, :actual_finish]
      t.index [:status, :percent_complete]

      # Check constraint for percent_complete
      t.check_constraint 'percent_complete >= 0 AND percent_complete <= 100', name: 'chk_percent_complete_range'

      # Unique constraint to prevent duplicate progress records
      t.index [:ifc_model_id, :element_id, :baseline_id], unique: true,
              name: 'index_element_progress_unique'
    end
  end
end
