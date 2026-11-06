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

class RenameMyWorkPreferencesToMyTimeManagement < ActiveRecord::Migration[8.1]
  KEYS = {
    "my_work_mode" => "my_time_management_mode",
    "my_work_view_mode" => "my_time_management_view_mode"
  }.freeze

  def up
    rename_keys(KEYS)
  end

  def down
    rename_keys(KEYS.invert)
  end

  private

  def rename_keys(mapping)
    old_keys = mapping.keys.map { |key| connection.quote(key) }.join(", ")
    new_pairs = mapping.map { |from, to| "#{connection.quote(to)}, settings->#{connection.quote(from)}" }.join(", ")

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = jsonb_strip_nulls(jsonb_build_object(#{new_pairs})) || (settings - ARRAY[#{old_keys}]),
          updated_at = NOW()
      WHERE settings ?| ARRAY[#{old_keys}]
    SQL
  end
end
