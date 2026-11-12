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

class FixUniquenessOnEnumerations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Get rid of old index
    remove_index :enumerations, name: "index_enumerations_on_type_project_id_and_LOWER_name", algorithm: :concurrently

    # As we did not really validate uniqueness before, we need to fix existing duplicates
    execute <<~SQL.squish
      UPDATE enumerations SET name = enumerations.name || ' ' || counter.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY type, COALESCE(project_id, -1), LOWER(name) ORDER BY id) AS rn FROM enumerations) AS counter
      WHERE enumerations.id = counter.id AND counter.rn > 1;
    SQL

    # Add the index again
    add_index :enumerations,
              "type, project_id, LOWER(name)",
              unique: true,
              algorithm: :concurrently,
              nulls_not_distinct: true,
              name: "index_enumerations_on_type_project_id_and_LOWER_name"
  end

  def down
    # roll back to the old version of the index
    remove_index :enumerations, name: "index_enumerations_on_type_project_id_and_LOWER_name", algorithm: :concurrently
    add_index :enumerations, "type, project_id, LOWER(name)", unique: true, algorithm: :concurrently,
                                                              name: "index_enumerations_on_type_project_id_and_LOWER_name"
  end
end
