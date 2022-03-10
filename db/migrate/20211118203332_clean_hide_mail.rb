class CleanHideMail < ActiveRecord::Migration[6.1]
  def up
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
  end

  def down
    # Nothing to do
  end
end
