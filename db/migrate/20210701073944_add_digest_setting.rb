class AddDigestSetting < ActiveRecord::Migration[6.1]
  def up
    # No-op
  end

  def down
    remove_digest_channels
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
