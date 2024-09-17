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

class CleanupUserPreferences < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'warn_on_leaving_unsaved' || '{"warn_on_leaving_unsaved": true}'
      WHERE settings ->> 'warn_on_leaving_unsaved' = '1'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'warn_on_leaving_unsaved' || '{"warn_on_leaving_unsaved": false}'
      WHERE settings ->> 'warn_on_leaving_unsaved' = '0'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'hide_mail' || '{"hide_mail": false}'
      WHERE settings ->> 'hide_mail' = '0'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'hide_mail' || '{"hide_mail": true}'
      WHERE settings ->> 'hide_mail' = '1'
    SQL

    # Remove all other keys from the user preferences
    object_map = UserPreferences::Schema.properties.map { |key| "'#{key}', settings->'#{key}'" }.join(", ")
    execute <<~SQL.squish
      WITH subquery AS (
        SELECT id,
               jsonb_strip_nulls(jsonb_build_object(#{object_map})) as stripped_settings
        FROM user_preferences
      )
      UPDATE user_preferences
      SET settings = subquery.stripped_settings
      FROM subquery
      WHERE user_preferences.id = subquery.id
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'warn_on_leaving_unsaved' || '{"warn_on_leaving_unsaved": "1"}'
      WHERE settings ->> 'warn_on_leaving_unsaved' = 'true'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'warn_on_leaving_unsaved' || '{"warn_on_leaving_unsaved": "0"}'
      WHERE settings ->> 'warn_on_leaving_unsaved' = 'false'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'hide_mail' || '{"hide_mail": 0}'
      WHERE settings ->> 'hide_mail' = 'true'
    SQL

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'hide_mail' || '{"hide_mail": 1}'
      WHERE settings ->> 'hide_mail' = 'false'
    SQL
  end
end
