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

class RepairCustomFieldSectionAttributeOrder < ActiveRecord::Migration[8.1]
  def up
    remove_keys_of_fields_in_other_sections
    append_missing_keys
  end

  def down; end

  private

  def remove_keys_of_fields_in_other_sections
    execute(<<~SQL.squish)
      UPDATE custom_field_sections cs
      SET attribute_order = ARRAY(
        SELECT attribute_order_item.key
        FROM UNNEST(cs.attribute_order) WITH ORDINALITY AS attribute_order_item(key, ordinal)
        WHERE NOT EXISTS (
          SELECT 1 FROM custom_fields cf
          WHERE 'cf_' || cf.id = attribute_order_item.key
            AND cf.custom_field_section_id <> cs.id
        )
        ORDER BY attribute_order_item.ordinal
      )
      WHERE EXISTS (
        SELECT 1 FROM custom_fields cf
        WHERE 'cf_' || cf.id = ANY(cs.attribute_order)
          AND cf.custom_field_section_id <> cs.id
      )
    SQL
  end

  def append_missing_keys
    execute(<<~SQL.squish)
      UPDATE custom_field_sections cs
      SET attribute_order = cs.attribute_order || missing.keys
      FROM (
        SELECT cf.custom_field_section_id AS section_id,
               ARRAY_AGG('cf_' || cf.id ORDER BY cf.id)::varchar[] AS keys
        FROM custom_fields cf
        INNER JOIN custom_field_sections s ON s.id = cf.custom_field_section_id
        WHERE NOT ('cf_' || cf.id = ANY(s.attribute_order))
        GROUP BY cf.custom_field_section_id
      ) missing
      WHERE cs.id = missing.section_id
    SQL
  end
end
