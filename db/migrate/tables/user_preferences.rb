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

require_relative "base"

class Tables::UserPreferences < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.bigint :user_id, null: false
      t.jsonb :settings, default: {}
      t.timestamps
      t.jsonb :dismissed_enterprise_banners, null: false, default: {}

      t.index :user_id,
              name: "index_user_preferences_on_user_id"
      t.index "(settings->'daily_reminders'->'enabled')",
              using: :gin,
              name: "index_user_prefs_settings_daily_reminders_enabled"
      t.index "(settings->'daily_reminders'->'times')",
              using: :gin,
              name: "index_user_prefs_settings_daily_reminders_times"
      t.index "(settings->'time_zone')",
              using: :gin,
              name: "index_user_prefs_settings_time_zone"
      t.index "(settings->'workdays')",
              using: :gin,
              name: "index_user_prefs_settings_workdays"
      t.index "((user_preferences.settings->'pause_reminders'->>'enabled')::boolean)",
              name: "index_user_prefs_settings_pause_reminders_enabled"
    end
  end
end
