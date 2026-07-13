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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddCaseInsensitiveUniquenessForProjectIdentifiers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    deduplicate_case_colliding_identifiers
    remove_index :projects, :identifier, unique: true, algorithm: :concurrently, if_exists: true
    add_index :projects, "LOWER(identifier)",
              unique: true,
              name: "index_projects_on_lower_identifier",
              algorithm: :concurrently,
              if_not_exists: true
  end

  # Note: does not undo identifier renames from deduplication. Suffixed identifiers
  # (e.g. "FOO_2") remain valid and unique under the restored case-sensitive index.
  def down
    remove_index :projects, name: "index_projects_on_lower_identifier", algorithm: :concurrently, if_exists: true
    add_index :projects, :identifier, unique: true, algorithm: :concurrently
  end

  private

  # Resolves any existing case-colliding identifiers (e.g. "Foo" and "foo") so that
  # the unique LOWER(identifier) index can be created without violation errors.
  # The oldest project (by id) keeps its identifier; duplicates get a "_N" suffix.
  #
  # The NOT EXISTS guard skips rows where the suffixed identifier would itself collide.
  # In practice this is extremely unlikely (requires both case-colliding identifiers
  # AND a pre-existing "_N" variant). If it occurs, the subsequent index creation
  # will fail, surfacing the issue for manual resolution.
  def deduplicate_case_colliding_identifiers
    execute <<~SQL.squish
      UPDATE projects SET identifier = projects.identifier || '_' || counter.rn
      FROM (
        SELECT id, row_number() OVER (PARTITION BY LOWER(identifier) ORDER BY id) AS rn
        FROM projects
      ) AS counter
      WHERE projects.id = counter.id AND counter.rn > 1
        AND NOT EXISTS (
          SELECT 1 FROM projects p2
          WHERE LOWER(p2.identifier) = LOWER(projects.identifier || '_' || counter.rn)
        );
    SQL
  end
end
