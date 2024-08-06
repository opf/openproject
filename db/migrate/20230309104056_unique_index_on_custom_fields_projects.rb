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

class UniqueIndexOnCustomFieldsProjects < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up { remove_duplicates }
    end

    remove_index :custom_fields_projects,
                 %i[custom_field_id project_id]

    add_index :custom_fields_projects,
              %i[custom_field_id project_id],
              unique: true
  end

  private

  # Selects all distinct tuples of (project_id, custom_field_id), then removes the whole content
  # of custom_fields_projects to then add the distinct tuples again.
  def remove_duplicates
    execute <<~SQL.squish
      WITH selection AS (
        SELECT
          project_id,
          custom_field_id
        FROM
          custom_fields_projects
        GROUP BY
          (project_id, custom_field_id)
      ),
      deletion AS (
        DELETE FROM
          custom_fields_projects
      ),
      insertion AS (
        INSERT INTO
          custom_fields_projects
          (
            project_id,
            custom_field_id
          )
        SELECT
          project_id,
          custom_field_id
        FROM
          selection
      )

      SELECT 1
    SQL
  end
end
