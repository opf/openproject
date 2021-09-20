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
