class AddNotificationSettings < ActiveRecord::Migration[6.1]
  def up
    create_table :notification_settings do |t|
      t.belongs_to :project, null: true, index: true, foreign_key: true
      t.belongs_to :user, null: false, index: true, foreign_key: true
      t.integer :channel, limit: 1
      t.boolean :watched, default: false
      t.boolean :involved, default: false
      t.boolean :mentioned, default: false
      t.boolean :all, default: false

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }

      t.index %i[user_id channel],
              unique: true,
              where: "project_id IS NULL",
              name: 'index_notification_settings_unique_project_null'

      t.index %i[user_id project_id channel],
              unique: true,
              where: "project_id IS NOT NULL",
              name: 'index_notification_settings_unique_project'
    end

    insert_project_specific_channel
    insert_default_mail_channel
    insert_default_in_app_channel

    remove_column :members, :mail_notification
  end

  def down
    add_column :members, :mail_notification, :boolean, default: false, null: false
    add_column :users, :mail_notification, :string, default: '', null: false

    update_mail_notifications

    drop_table :notification_settings
  end

  def insert_default_mail_channel
    execute <<~SQL
      INSERT INTO
        notification_settings
        (user_id,
         channel,
         watched,
         involved,
         mentioned,
         "all")
      SELECT
        id,
        1,
        mail_notification = 'only_my_events',
        mail_notification = 'only_my_events' OR mail_notification = 'only_assigned',
        NOT mail_notification = 'all' AND NOT mail_notification = 'NONE',
        mail_notification = 'all'
      FROM
        users
      WHERE
        mail_notification IS NOT NULL
    SQL
  end

  def insert_project_specific_channel
    execute <<~SQL
      INSERT INTO
        notification_settings
        (project_id,
         user_id,
         channel,
         "all")
      SELECT
        project_id,
        user_id,
        1,
        true
      FROM
        members
      WHERE
        mail_notification
    SQL
  end

  def insert_default_in_app_channel
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
        0,
        true,
        true,
        true
      FROM
        users
      WHERE
        type = 'User'
    SQL
  end

  def update_mail_notifications
    # We cannot reconstruct the settings completely
    execute <<~SQL
      UPDATE
        users
      SET
        mail_notification = CASE
                            WHEN notification_settings.all
                              THEN 'all'
                            WHEN notification_settings.watched
                              THEN 'only_my_events'
                            WHEN notification_settings.involved
                              THEN 'only_assigned'
                            ELSE 'none'
      FROM
        notification_settings
      WHERE
        notification_settings.user_id = users.id
    SQL
  end
end
