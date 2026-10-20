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

class MoveUserPreferenceColumnsIntoSettings < ActiveRecord::Migration[8.1]
  FLAT_REMINDER_KEYS = %w[
    daily_reminders_enabled
    daily_reminders_times
    immediate_reminders_mentioned
    immediate_reminders_personal_reminder
    pause_reminders_enabled
    pause_reminders_first_day
    pause_reminders_last_day
  ].freeze

  def up
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = (COALESCE(settings, '{}'::jsonb) - '{daily_reminders,immediate_reminders,pause_reminders}'::text[])
        || jsonb_strip_nulls(
          jsonb_build_object(
            'dismissed_enterprise_banners', NULLIF(dismissed_enterprise_banners, '{}'::jsonb),
            'whats_new_read_items', NULLIF(whats_new_read_items, '{}'::jsonb),
            'whats_new_seen_version', whats_new_seen_version,
            'whats_new_seen_at', to_char(whats_new_seen_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
            'daily_reminders_enabled', settings->'daily_reminders'->'enabled',
            'daily_reminders_times', settings->'daily_reminders'->'times',
            'immediate_reminders_mentioned', settings->'immediate_reminders'->'mentioned',
            'immediate_reminders_personal_reminder', settings->'immediate_reminders'->'personal_reminder',
            'pause_reminders_enabled', settings->'pause_reminders'->'enabled',
            'pause_reminders_first_day', settings->'pause_reminders'->'first_day',
            'pause_reminders_last_day', settings->'pause_reminders'->'last_day'
          )
        )
    SQL

    change_table :user_preferences, bulk: true do |t|
      t.remove :dismissed_enterprise_banners,
               :whats_new_read_items,
               :whats_new_seen_version,
               :whats_new_seen_at
    end

    remove_reminder_indexes
    add_index :user_preferences, "((settings->>'daily_reminders_enabled')::boolean)",
              name: "index_user_prefs_settings_daily_reminders_enabled"
    add_index :user_preferences, "(settings->'daily_reminders_times')",
              using: :gin,
              name: "index_user_prefs_settings_daily_reminders_times"
    add_index :user_preferences, "((settings->>'pause_reminders_enabled')::boolean)",
              name: "index_user_prefs_settings_pause_reminders_enabled"
  end

  def down
    change_table :user_preferences, bulk: true do |t|
      t.jsonb :dismissed_enterprise_banners, null: false, default: {}
      t.jsonb :whats_new_read_items, null: false, default: {}
      t.string :whats_new_seen_version
      t.datetime :whats_new_seen_at
    end

    execute <<~SQL.squish
      UPDATE user_preferences
      SET dismissed_enterprise_banners = COALESCE(settings->'dismissed_enterprise_banners', '{}'::jsonb),
          whats_new_read_items = COALESCE(settings->'whats_new_read_items', '{}'::jsonb),
          whats_new_seen_version = settings->>'whats_new_seen_version',
          whats_new_seen_at = (settings->>'whats_new_seen_at')::timestamptz AT TIME ZONE 'UTC',
          settings = (settings
                      - '{dismissed_enterprise_banners,whats_new_read_items,whats_new_seen_version,whats_new_seen_at}'::text[]
                      - '{#{FLAT_REMINDER_KEYS.join(',')}}'::text[])
            || jsonb_strip_nulls(
              jsonb_build_object(
                'daily_reminders',
                CASE WHEN settings ?| '{daily_reminders_enabled,daily_reminders_times}'::text[] THEN
                  jsonb_build_object('enabled', settings->'daily_reminders_enabled',
                                     'times', settings->'daily_reminders_times')
                END,
                'immediate_reminders',
                CASE WHEN settings ?| '{immediate_reminders_mentioned,immediate_reminders_personal_reminder}'::text[] THEN
                  jsonb_build_object('mentioned', settings->'immediate_reminders_mentioned',
                                     'personal_reminder', settings->'immediate_reminders_personal_reminder')
                END,
                'pause_reminders',
                CASE WHEN settings ?| '{pause_reminders_enabled,pause_reminders_first_day,pause_reminders_last_day}'::text[] THEN
                  jsonb_build_object('enabled', settings->'pause_reminders_enabled',
                                     'first_day', settings->'pause_reminders_first_day',
                                     'last_day', settings->'pause_reminders_last_day')
                END
              )
            )
    SQL

    remove_reminder_indexes
    add_index :user_preferences, "(settings->'daily_reminders'->'enabled')",
              using: :gin,
              name: "index_user_prefs_settings_daily_reminders_enabled"
    add_index :user_preferences, "(settings->'daily_reminders'->'times')",
              using: :gin,
              name: "index_user_prefs_settings_daily_reminders_times"
    add_index :user_preferences, "((user_preferences.settings->'pause_reminders'->>'enabled')::boolean)",
              name: "index_user_prefs_settings_pause_reminders_enabled"
  end

  private

  def remove_reminder_indexes
    remove_index :user_preferences, name: "index_user_prefs_settings_daily_reminders_enabled"
    remove_index :user_preferences, name: "index_user_prefs_settings_daily_reminders_times"
    remove_index :user_preferences, name: "index_user_prefs_settings_pause_reminders_enabled"
  end
end
