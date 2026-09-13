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

class CreateBimProgressBaselines < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_progress_baselines do |t|
      # Project reference
      t.references :project, foreign_key: true, null: false

      # Baseline metadata
      t.string :name, limit: 255, null: false
      t.text :description
      t.date :snapshot_date, null: false

      # Statistics (denormalized for performance)
      t.integer :total_elements, default: 0, null: false
      t.integer :completed_elements, default: 0, null: false
      t.integer :in_progress_elements, default: 0, null: false
      t.integer :planned_elements, default: 0, null: false
      t.decimal :overall_progress, precision: 5, scale: 2, default: 0.0

      # User tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      # Status
      t.integer :status, default: 0, null: false # active, archived
      t.boolean :is_current, default: false

      t.timestamps

      # Indexes
      t.index :project_id
      t.index :snapshot_date
      t.index :status
      t.index [:project_id, :is_current]
      t.index [:project_id, :snapshot_date]
      t.index :created_by_id
    end
  end
end
