require_relative './migration_utils/utils'

class AddReminderWorkdays < ActiveRecord::Migration[6.1]
  include ::Migration::Utils

  def up
    add_index :user_preferences,
              "(settings->'workdays')",
              using: :gin,
              name: :index_user_prefs_settings_workdays
  end

  def down
    remove_index_if_exists :user_preferences, :index_user_prefs_settings_workdays
  end
end
