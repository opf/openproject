class AddDigestSetting < ActiveRecord::Migration[6.1]
  def up
    insert_default_digest_channel
  end

  def down
    remove_digest_channels
  end

  def insert_default_digest_channel
    execute <<~SQL
      INSERT INTO
        notification_settings
        (user_id,
         channel,
         involved,
         mentioned,
         watched)
      SELECT
        id,
        2,
        true,
        true,
        true
      FROM
        users
      WHERE
        type = 'User'
    SQL
  end

  # Removes all digest channels. Includes non default channels as those might
  # also have been added not by the migration but in the cause of the functionality
  # the migration was added for.
  def remove_digest_channels
    execute <<~SQL
      DELETE FROM
        notification_settings
      WHERE
        channel = 2
    SQL
  end
end
