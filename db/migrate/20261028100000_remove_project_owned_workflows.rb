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

require Rails.root.join("db/migrate/migration_utils/utils")

class RemoveProjectOwnedWorkflows < ActiveRecord::Migration[8.1]
  include Migration::Utils

  NAME_INDEX = "index_workflows_on_LOWER_name"
  OWNED_NAME_INDEX = "index_workflows_on_project_id_and_LOWER_name"

  def up
    execute <<~SQL.squish
      UPDATE type_variants
      SET workflow_id = defaults.workflow_id
      FROM type_variants defaults, workflows
      WHERE workflows.id = type_variants.workflow_id
        AND workflows.project_id IS NOT NULL
        AND defaults.type_id = type_variants.type_id
        AND defaults.is_default_variant
    SQL

    execute "DELETE FROM workflows WHERE project_id IS NOT NULL"

    remove_index_on :workflows, OWNED_NAME_INDEX
    remove_reference :workflows, :project, foreign_key: { on_delete: :cascade }, index: true
    add_index :workflows, "lower(name)", unique: true, name: NAME_INDEX, if_not_exists: true
  end

  def down
    remove_index_on :workflows, NAME_INDEX
    add_reference :workflows, :project, null: true, foreign_key: { on_delete: :cascade }, index: true
    add_index :workflows, "lower(name)", unique: true, where: "project_id IS NULL", name: NAME_INDEX
    add_index :workflows, "project_id, lower(name)", unique: true, where: "project_id IS NOT NULL",
                                                     name: OWNED_NAME_INDEX
  end
end
