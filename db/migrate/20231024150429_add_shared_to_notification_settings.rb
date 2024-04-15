class AddSharedToNotificationSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :notification_settings, :shared, :boolean, default: false, null: false
  end
end
