class ChangeDefaultsForNotificationSettings < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.change_default :assignee, from: false, to: true
      t.change_default :responsible, from: false, to: true
      t.change_default :mentioned, from: false, to: true
      t.change_default :watched, from: false, to: true
    end
  end
end
