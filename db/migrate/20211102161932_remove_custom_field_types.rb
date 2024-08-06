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

class RemoveCustomFieldTypes < ActiveRecord::Migration[6.1]
  def up
    delete_custom_field("TimeEntryActivityCustomField")
    delete_custom_field("DocumentCategoryCustomField")
    delete_custom_field("IssuePriorityCustomField")

    delete_custom_values
  end

  def delete_custom_field(type)
    execute <<~SQL.squish
      DELETE FROM
        custom_fields
      WHERE
        type = '#{type}'
    SQL
  end

  def delete_custom_values
    execute <<~SQL.squish
      DELETE FROM
        custom_values values_delete
      USING
        custom_values values_select
      LEFT OUTER JOIN
        custom_fields
      ON
        custom_fields.id = values_select.custom_field_id
      WHERE
        values_delete.id = values_select.id
      AND
        custom_fields.id IS NULL
    SQL
  end
end
