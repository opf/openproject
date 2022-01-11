class FixMissingNotificationSettings < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      INSERT INTO
        notification_settings
        (user_id, watched, involved, mentioned)
      SELECT
        u.id, true, true, true
      FROM
        users u
      WHERE type = 'User'
      AND NOT EXISTS (SELECT * FROM notification_settings ns WHERE ns.user_id = u.id)
    SQL
  end

  def down
    # No data to revert
  end
end
