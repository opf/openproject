class AddNotificationSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_settings do |t|
      t.belongs_to :project, null: true, index: true, foreign_key: true
      t.belongs_to :user, null: false, index: true, foreign_key: true
      t.integer :channel, limit: 1
      t.boolean :watched, default: false
      t.boolean :involved, default: false
      t.boolean :mentioned, default: false
      t.boolean :all, default: false

      t.timestamps

      t.index %i[user_id project_id channel],
              unique: true,
              name: 'index_notification_settings_unique_join'
    end

  end
end
