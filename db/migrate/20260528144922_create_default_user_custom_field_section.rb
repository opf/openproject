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

class CreateDefaultUserCustomFieldSection < ActiveRecord::Migration[8.1]
  def up
    section_id = execute(<<~SQL.squish).first["id"]
      INSERT INTO custom_field_sections (type, name, position, created_at, updated_at)
      VALUES ('UserCustomFieldSection', NULL, 1, NOW(), NOW())
      RETURNING id
    SQL

    execute(<<~SQL.squish)
      UPDATE custom_fields
      SET custom_field_section_id = #{section_id}
      WHERE type = 'UserCustomField'
        AND custom_field_section_id IS NULL
    SQL
  end

  def down
    execute(<<~SQL.squish)
      UPDATE custom_fields
      SET custom_field_section_id = NULL
      WHERE type = 'UserCustomField'
        AND custom_field_section_id IN (
          SELECT id FROM custom_field_sections
          WHERE type = 'UserCustomFieldSection' AND name IS NULL
        )
    SQL

    execute(<<~SQL.squish)
      DELETE FROM custom_field_sections
      WHERE type = 'UserCustomFieldSection' AND name IS NULL
    SQL
  end
end
