class RemoveHideMailFromUserPreferences < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings =  settings - 'hide_mail'
    SQL
  end
end
