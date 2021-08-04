class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.boolean :work_package_commented, default: false
      t.boolean :work_package_created, default: false
      t.boolean :work_package_processed, default: false
    end

    # TODO: remove existing notification setting from settings
  end
end
