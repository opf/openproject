class SetWatchedNotificationSettingToTrue < ActiveRecord::Migration[7.1]
  def change
    change_column_default :notification_settings, :shared, from: false, to: true

    reversible do |dir|
      dir.up do
        execute "UPDATE notification_settings SET shared = true"
      end

      dir.down do
        execute "UPDATE notification_settings SET shared = false"
      end
    end
  end
end
