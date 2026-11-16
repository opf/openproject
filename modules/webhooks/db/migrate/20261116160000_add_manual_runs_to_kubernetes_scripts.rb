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

require Rails.root.join("db/migrate/migration_utils/permission_adder")

class AddManualRunsToKubernetesScripts < ActiveRecord::Migration[8.0]
  def up
    change_table :webhooks_kubernetes_scripts, bulk: true do |t|
      t.boolean :manual, null: false, default: false
      t.string :button_label
      t.json :input_schema
      t.bigint :type_ids, array: true, null: false, default: []
    end

    change_table :webhooks_kubernetes_script_runs, bulk: true do |t|
      t.string :trigger, null: false, default: "event"
      t.references :triggered_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :work_package, foreign_key: { on_delete: :nullify }
      t.jsonb :input
    end

    ::Migration::MigrationUtils::PermissionAdder.add(:edit_work_packages, :run_manual_scripts)
    execute <<~SQL.squish
      DELETE FROM role_permissions
      WHERE permission = 'run_manual_scripts'
        AND role_id IN (SELECT project_role_id FROM webhooks_kubernetes_scripts WHERE project_role_id IS NOT NULL)
    SQL
  end

  def down
    execute "DELETE FROM role_permissions WHERE permission = 'run_manual_scripts'"
    change_table :webhooks_kubernetes_script_runs, bulk: true do |t|
      t.remove_references :triggered_by, :work_package
      t.remove :trigger, :input
    end
    change_table :webhooks_kubernetes_scripts, bulk: true do |t|
      t.remove :manual, :button_label, :input_schema, :type_ids
    end
  end
end
