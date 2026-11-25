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

class RemovePositionInCustomFieldSectionFromCustomFields < ActiveRecord::Migration[8.0]
  def up
    return unless column_exists?(:custom_fields, :position_in_custom_field_section)

    # Populate attribute_order for every section from the existing position ordering.
    # COALESCE handles sections that currently have no custom fields (ARRAY_AGG returns NULL).
    execute(<<~SQL.squish)
      UPDATE custom_field_sections cs
      SET attribute_order = COALESCE(
        (
          SELECT ARRAY_AGG('cf_' || cf.id::text ORDER BY cf.position_in_custom_field_section)
          FROM custom_fields cf
          WHERE cf.custom_field_section_id = cs.id
        ),
        '{}'
      )
      WHERE cs.type = 'ProjectCustomFieldSection'
    SQL

    remove_column :custom_fields, :position_in_custom_field_section
  end

  def down
    add_column :custom_fields, :position_in_custom_field_section, :integer

    # Restore per-section positions from attribute_order in case they have been
    # changed already.
    # UNNEST … WITH ORDINALITY yields each key with its 1-based rank.
    # Built-in keys (login, firstname, …) don't follow the cf_<id> pattern
    # and are filtered out by the regex so the cast to integer is safe.
    execute(<<~SQL.squish)
      UPDATE custom_fields cf
      SET position_in_custom_field_section = positions.ordinal
      FROM (
        SELECT
          SUBSTRING(key FROM 4)::integer AS cf_id,
          ordinal::integer
        FROM custom_field_sections cs,
          LATERAL UNNEST(cs.attribute_order) WITH ORDINALITY AS unnested(key, ordinal)
        WHERE cs.type = 'ProjectCustomFieldSection'
          AND key ~ '^cf_[0-9]+$'
      ) positions
      WHERE cf.id = positions.cf_id
    SQL
  end
end
