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

class CreateTmCases < ActiveRecord::Migration[8.1]
  def change # rubocop:disable Metrics/AbcSize
    create_table :tm_project_settings do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :display_prefix, limit: 32
      t.jsonb :options, null: false, default: {}
      t.timestamps null: false
    end

    create_table :tm_suites do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :parent, foreign_key: { to_table: :tm_suites, on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.integer :position, null: false, default: 0
      t.timestamps null: false
    end
    add_index :tm_suites, %i[project_id parent_id name],
              unique: true, nulls_not_distinct: true, name: "index_tm_suites_on_project_parent_name"

    create_table :tm_test_cases do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :suite, foreign_key: { to_table: :tm_suites, on_delete: :nullify }, index: true
      t.string :title, null: false, limit: 255
      t.text :description
      t.text :preconditions
      t.string :priority, null: false, default: "medium", limit: 32
      t.string :status, null: false, default: "ready", limit: 32
      t.boolean :automated, null: false, default: false
      t.string :automation_reference, limit: 1024
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_index :tm_test_cases, %i[project_id status]
    add_index :tm_test_cases, %i[project_id automation_reference],
              unique: true, where: "automation_reference IS NOT NULL",
              name: "index_tm_test_cases_on_project_and_automation_ref"

    create_table :tm_test_steps do |t|
      t.references :test_case, null: false, foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }, index: false
      t.integer :position, null: false, default: 0
      t.text :action
      t.text :expected_result
      t.text :data
      t.timestamps null: false
    end
    add_index :tm_test_steps, %i[test_case_id position]
  end
end
