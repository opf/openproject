class AddUserPreferenceSettingsIndices < ActiveRecord::Migration[6.1]
  def change
    add_index :user_preferences,
              "(settings->'daily_reminders'->'enabled')",
              using: :gin,
              name: 'index_user_prefs_settings_daily_reminders_enabled'

    add_index :user_preferences,
              "(settings->'daily_reminders'->'times')",
              using: :gin,
              name: 'index_user_prefs_settings_daily_reminders_times'

    add_index :user_preferences,
              "(settings->'time_zone')",
              using: :gin,
              name: 'index_user_prefs_settings_time_zone'
  end
end
