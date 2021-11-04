class DefaultNotificationSetting < ActiveRecord::Migration[6.1]
  def up
    NotificationSetting.delete_all

    execute <<~SQL.squish
      INSERT INTO
        notification_settings
        (user_id, watched, involved, mentioned)
      SELECT
        id, true, true, true
      FROM
        users
    SQL
  end

  def down
    # No data to revert
  end
end
