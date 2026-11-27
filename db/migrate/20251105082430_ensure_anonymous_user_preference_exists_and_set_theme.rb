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

class EnsureAnonymousUserPreferenceExistsAndSetTheme < ActiveRecord::Migration[8.0]
  def up
    say "Ensure anonymous user has preferences and set theme to sync_with_os"

    execute <<~SQL.squish
      INSERT INTO user_preferences (user_id, settings, created_at, updated_at)
      SELECT id, '{"theme": "sync_with_os"}'::jsonb, NOW(), NOW()
      FROM users
      WHERE type = 'AnonymousUser'
      ON CONFLICT (user_id)
      DO UPDATE SET
        settings = user_preferences.settings || '{"theme": "sync_with_os"}'::jsonb,
        updated_at = NOW();
    SQL
  end

  def down
    say "Rollback: reset anonymous user theme to light"

    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = settings || '{"theme": "light"}'::jsonb,
          updated_at = NOW()
      WHERE user_id IN (SELECT id FROM users WHERE type = 'AnonymousUser');
    SQL
  end
end
