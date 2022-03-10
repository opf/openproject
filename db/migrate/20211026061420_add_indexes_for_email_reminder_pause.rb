require_relative './migration_utils/utils'

class AddIndexesForEmailReminderPause < ActiveRecord::Migration[6.1]
  include ::Migration::Utils

  def up
    add_index :user_preferences,
              "((user_preferences.settings->'pause_reminders'->>'enabled')::boolean)",
              name: :index_user_prefs_settings_pause_reminders_enabled
  end

  def down
    remove_index_if_exists :user_preferences, :index_user_prefs_settings_pause_reminders_enabled
  end
end
