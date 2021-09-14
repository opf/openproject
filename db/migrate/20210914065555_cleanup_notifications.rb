class CleanupNotifications < ActiveRecord::Migration[6.1]
  def up
    change_table :notifications, bulk: true do |t|
      t.remove :read_mail, :reason_mail, :reason_mail_digest
      t.rename :reason_ian, :reason
    end

    change_table :notification_settings, bulk: true do |t|
      t.remove_index name: 'index_notification_settings_unique_project_null'
      t.remove_index name: 'index_notification_settings_unique_project'

      # Delete all non in-app
      NotificationSetting.where('channel > 0').delete_all

      t.remove :channel, :all

      t.index %i[user_id],
              unique: true,
              where: "project_id IS NULL",
              name: 'index_notification_settings_unique_project_null'

      t.index %i[user_id project_id],
              unique: true,
              where: "project_id IS NOT NULL",
              name: 'index_notification_settings_unique_project'
    end
  end

  def down
    change_table :notifications, bulk: true do |t|
      t.boolean :read_mail, default: false, index: true
      t.integer :reason_mail, limit: 1
      t.integer :reason_mail_digest, limit: 1
      t.rename :reason, :reason_ian
    end

    change_table :notification_settings, bulk: true do |t|
      t.integer :channel, limit: 1
      t.boolean :all, default: false

      t.remove_index name: 'index_notification_settings_unique_project_null'
      t.remove_index name: 'index_notification_settings_unique_project'

      t.index %i[user_id channel],
              unique: true,
              where: "project_id IS NULL",
              name: 'index_notification_settings_unique_project_null'

      t.index %i[user_id project_id channel],
              unique: true,
              where: "project_id IS NOT NULL",
              name: 'index_notification_settings_unique_project'
    end

    # Set all channels to ian
    execute <<~SQL.squish
      UPDATE notification_settings SET channel = 0;
    SQL

    # Restore notification settings
    execute <<~SQL.squish
      INSERT INTO notification_settings
        (project_id, user_id, channel, watched, involved, mentioned,
        work_package_commented, work_package_created, work_package_processed, work_package_prioritized, work_package_scheduled)
      SELECT project_id, user_id, channel + 1, watched, involved, mentioned,
        work_package_commented, work_package_created, work_package_processed, work_package_prioritized, work_package_scheduled
      FROM notification_settings
      UNION
      SELECT project_id, user_id, channel + 2, watched, involved, mentioned,
        work_package_commented, work_package_created, work_package_processed, work_package_prioritized, work_package_scheduled
      FROM notification_settings;
    SQL
  end
end
