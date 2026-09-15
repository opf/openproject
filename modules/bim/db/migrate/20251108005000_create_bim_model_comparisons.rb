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

class CreateBimModelComparisons < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_model_comparisons do |t|
      # Models being compared
      t.references :model1, foreign_key: { to_table: :ifc_models }, null: false
      t.references :model2, foreign_key: { to_table: :ifc_models }, null: false

      # Comparison metadata
      t.string :name, limit: 255
      t.text :description
      t.string :comparison_type, limit: 50, default: 'version' # version, baseline, federated

      # Change counts (denormalized for performance)
      t.integer :added_count, default: 0, null: false
      t.integer :deleted_count, default: 0, null: false
      t.integer :modified_count, default: 0, null: false
      t.integer :unchanged_count, default: 0, null: false

      # Detailed changes data
      t.jsonb :changes_data, default: {}
      t.jsonb :statistics, default: {}

      # Comparison settings
      t.jsonb :comparison_options, default: {}

      # User tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.datetime :approved_at

      # Status tracking
      t.integer :status, default: 0, null: false # pending, completed, approved, rejected
      t.text :status_comment

      # Performance metrics
      t.decimal :comparison_time, precision: 10, scale: 4
      t.datetime :completed_at

      t.timestamps

      # Indexes
      t.index :model1_id
      t.index :model2_id
      t.index [:model1_id, :model2_id]
      t.index :comparison_type
      t.index :status
      t.index :created_by_id
      t.index :created_at
      t.index :changes_data, using: :gin
      t.index :statistics, using: :gin
      t.index :comparison_options, using: :gin

      # Composite indexes for common queries
      t.index [:model1_id, :status]
      t.index [:model1_id, :created_at]
      t.index [:created_by_id, :status]
    end
  end
end
