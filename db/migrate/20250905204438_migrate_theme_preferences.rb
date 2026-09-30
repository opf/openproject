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

class MigrateThemePreferences < ActiveRecord::Migration[8.0]
  def up
    migrate_theme_preferences_to_new_structure
  end

  def down
    migrate_theme_preferences_to_old_structure
  end

  private

  def migrate_theme_preferences_to_new_structure
    say "Migrate light_high_contrast -> light theme with increase_theme_contrast: true"
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = settings || '{"theme": "light", "increase_theme_contrast": true}'::jsonb
      WHERE settings ->> 'theme' = 'light_high_contrast';
    SQL

    say "Migrate dark_high_contrast -> dark theme with increase_theme_contrast: true"
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = settings || '{"theme": "dark", "increase_theme_contrast": true}'::jsonb
      WHERE settings ->> 'theme' = 'dark_high_contrast';
    SQL
  end

  def migrate_theme_preferences_to_old_structure
    say "Rollback: Convert light theme with high contrast back to light_high_contrast"
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = (settings - 'increase_theme_contrast') || '{"theme": "light_high_contrast"}'::jsonb
      WHERE settings ->> 'theme' = 'light'
        AND (settings ->> 'increase_theme_contrast')::boolean = true;
    SQL

    say "Rollback: Convert dark theme with high contrast back to dark_high_contrast"
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = (settings - 'increase_theme_contrast') || '{"theme": "dark_high_contrast"}'::jsonb
        WHERE settings ->> 'theme' = 'dark'
          AND (settings ->> 'increase_theme_contrast')::boolean = true;
    SQL
  end
end
