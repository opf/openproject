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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreatePredefinedWorkPackageFilters < ActiveRecord::Migration[8.1]
  WORK_PACKAGE_VIEWS = %w[all_open to_do in_progress latest_activity recently_created overdue
                          summary created_by_me assigned_to_me shared_with_users shared_with_me].freeze

  def up
    create_filters_table
    create_project_assignments_table
    insert_builtin_filters
  end

  def down
    drop_table :predefined_work_package_filter_projects
    drop_table :predefined_work_package_filters
  end

  private

  def create_filters_table
    create_table :predefined_work_package_filters do |t|
      t.string :builtin_key
      t.string :name
      t.integer :position, null: false
      t.boolean :project_overview, null: false, default: false
      t.boolean :work_packages, null: false, default: false
      t.boolean :gantt, null: false, default: false
      t.jsonb :query_properties, null: false, default: {}
      t.timestamps

      t.index :builtin_key, unique: true
    end
  end

  def create_project_assignments_table
    create_table :predefined_work_package_filter_projects do |t|
      t.references :filter, null: false, index: false,
                            foreign_key: { to_table: :predefined_work_package_filters, on_delete: :cascade }
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :active, null: false, default: false
      t.timestamps

      t.index %i[filter_id project_id], unique: true
    end
  end

  def insert_builtin_filters
    (WORK_PACKAGE_VIEWS + ["milestones"]).each.with_index(1) do |key, position|
      execute <<~SQL.squish
        INSERT INTO predefined_work_package_filters (builtin_key, position, work_packages, gantt, created_at, updated_at)
        VALUES (#{quote(key)}, #{position}, #{WORK_PACKAGE_VIEWS.include?(key)},
                #{%w[all_open milestones].include?(key)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end
  end
end
