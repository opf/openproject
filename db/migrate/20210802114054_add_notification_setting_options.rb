class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    add_column :notification_settings, :work_package_commented, :boolean, default: false

    # TODO: remove existing notification setting from settings
  end
end
