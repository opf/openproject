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

class CreateTmRuns < ActiveRecord::Migration[8.1]
  def change # rubocop:disable Metrics/AbcSize
    create_table :tm_test_runs do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.string :state, null: false, default: "new", limit: 32
      t.string :selection_mode, null: false, default: "specific", limit: 16
      t.jsonb :filter_options, null: false, default: {}
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :finished_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.date :start_date
      t.date :end_date
      t.datetime :finished_at
      t.string :source, null: false, default: "manual", limit: 16
      t.string :completion_source, limit: 16
      t.string :external_ref, limit: 255
      t.jsonb :ci_metadata, null: false, default: {}
      t.string :ci_trigger_status, limit: 16
      t.string :ci_trigger_url, limit: 1024
      t.text :ci_trigger_error
      t.datetime :ci_triggered_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_index :tm_test_runs, %i[project_id state]
    add_index :tm_test_runs, %i[project_id external_ref],
              unique: true, where: "external_ref IS NOT NULL",
              name: "index_tm_test_runs_on_project_and_external_ref"

    create_table :tm_test_run_cases do |t|
      t.references :test_run, null: false, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: false
      t.references :test_case, null: false, foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.string :status, null: false, default: "untested", limit: 32
      t.string :final_status, limit: 32
      t.timestamps null: false
    end
    add_index :tm_test_run_cases, %i[test_run_id test_case_id], unique: true

    create_table :tm_test_run_iterations do |t|
      t.references :test_run, null: false, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: false
      t.integer :number, null: false
      t.string :name, limit: 255
      t.string :source, null: false, default: "manual", limit: 16
      t.string :external_ref, limit: 255
      t.jsonb :ci_metadata, null: false, default: {}
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_run_iterations, %i[test_run_id number],
              unique: true, name: "index_tm_run_iterations_on_run_and_number"
    add_index :tm_test_run_iterations, %i[test_run_id external_ref],
              unique: true, where: "external_ref IS NOT NULL",
              name: "index_tm_run_iterations_on_run_and_external_ref"

    create_table :tm_test_results do |t|
      t.references :run_case, null: false, foreign_key: { to_table: :tm_test_run_cases, on_delete: :cascade }, index: false
      t.references :iteration, foreign_key: { to_table: :tm_test_run_iterations, on_delete: :nullify }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :status, null: false, limit: 32
      t.text :comment
      t.string :source, null: false, default: "manual", limit: 16
      t.integer :duration_ms
      t.string :external_id, limit: 1024
      t.text :error_message
      t.text :error_trace
      t.jsonb :details, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :tm_test_results, %i[run_case_id created_at]
  end
end
