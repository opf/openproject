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

class CreateTmCi < ActiveRecord::Migration[8.1]
  def change # rubocop:disable Metrics/AbcSize
    create_table :tm_ci_connections do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false, limit: 255
      t.string :provider, null: false, limit: 16
      t.string :repository, null: false, limit: 255
      t.text :token_ciphertext
      t.datetime :token_updated_at
      t.string :workflow, limit: 255
      t.string :trigger_ref, limit: 255
      t.string :ingest_mode, null: false, default: "new_run", limit: 16
      t.string :target_run_name, limit: 255
      t.boolean :active, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_ci_connections, "project_id, lower(name)",
              unique: true, name: "index_tm_ci_connections_on_project_and_name"
    add_index :tm_ci_connections, %i[project_id provider repository],
              unique: true, name: "index_tm_ci_connections_on_project_and_repo"

    create_table :tm_automation_imports do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :test_run, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: false
      t.references :iteration, foreign_key: { to_table: :tm_test_run_iterations, on_delete: :nullify }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :format, null: false, limit: 32
      t.string :state, null: false, default: "queued", limit: 16
      t.string :digest, limit: 64
      t.string :external_ref, limit: 255
      t.integer :parsed_count, null: false, default: 0
      t.integer :matched_count, null: false, default: 0
      t.integer :created_cases_count, null: false, default: 0
      t.integer :unmatched_count, null: false, default: 0
      t.jsonb :unmatched, null: false, default: []
      t.jsonb :warnings, null: false, default: []
      t.jsonb :options, null: false, default: {}
      t.text :error
      t.timestamps null: false
    end
    add_index :tm_automation_imports, %i[test_run_id iteration_id digest],
              unique: true, where: "digest IS NOT NULL",
              name: "index_tm_automation_imports_on_iteration_and_digest"

    add_reference :tm_test_runs, :connection,
                  foreign_key: { to_table: :tm_ci_connections, on_delete: :nullify }, index: true
    add_reference :tm_test_run_iterations, :connection,
                  foreign_key: { to_table: :tm_ci_connections, on_delete: :nullify }, index: true
    add_reference :tm_test_results, :import,
                  foreign_key: { to_table: :tm_automation_imports, on_delete: :nullify }, index: true
  end
end
