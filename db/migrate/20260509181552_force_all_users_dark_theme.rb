# frozen_string_literal: true

class ForceAllUsersDarkTheme < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE user_preferences
      SET settings = settings || '{"theme": "dark"}'
    SQL

    execute <<~SQL
      UPDATE settings
      SET value = 'dark'
      WHERE name = 'user_default_theme'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE user_preferences
      SET settings = settings - 'theme'
    SQL

    execute <<~SQL
      UPDATE settings
      SET value = 'light'
      WHERE name = 'user_default_theme'
    SQL
  end
end
