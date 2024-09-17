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

class AddPrimaryKeyToCustomFieldsProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :custom_fields_projects, :id, :primary_key # rubocop:disable Rails/DangerousColumnNames

    reversible do |dir|
      dir.up do
        # Backfill the id column for existing rows
        execute <<-SQL.squish
          WITH cte AS (
            SELECT row_number() OVER () AS row_num, project_id, custom_field_id
            FROM custom_fields_projects
          )
          UPDATE custom_fields_projects
          SET id = cte.row_num
          FROM cte
          WHERE custom_fields_projects.project_id = cte.project_id
            AND custom_fields_projects.custom_field_id = cte.custom_field_id;
        SQL
      end
    end
  end
end
