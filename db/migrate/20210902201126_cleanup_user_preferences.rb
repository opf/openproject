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
      SET settings = settings - 'no_self_notified'
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
  end
end
