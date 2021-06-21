class AddNotificationSettings < ActiveRecord::Migration[6.1]
  # TODO:
  #   * Migrate data from members over to notification settings
  #   * Migrate mail_notification from users over to notification settings
  def change
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
  end
end
