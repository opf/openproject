require_relative './migration_utils/utils'

class AddReminderWorkdays < ActiveRecord::Migration[6.1]
  include ::Migration::Utils

  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE user_preferences
          SET settings =  settings || '{ "workdays": [1,2,3,4,5] }'
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          UPDATE user_preferences
          SET settings =  settings - 'workdays'
        SQL
      end
    end

    reversible do |dir|
      dir.up do
        add_index :user_preferences,
                  "(settings->'workdays')",
                  using: :gin,
                  name: :index_user_prefs_settings_workdays

      end

      dir.down do
        remove_index_if_exists :user_preferences, :index_user_prefs_settings_workdays
      end
    end
  end
end
