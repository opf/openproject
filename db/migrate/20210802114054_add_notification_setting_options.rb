class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    add_notification_settings_options
  end

  def add_notification_settings_options
    change_table :notification_settings, bulk: true do |t|
      # Adding indices here is probably useful as most of those are expected to be false
      # and we are searching for those that are true.
      # The columns watched, involved and mentioned will probably be true most of the time
      # so having an index there should not improve speed.
      t.boolean :work_package_commented, default: false, index: true
      t.boolean :work_package_created, default: false, index: true
      t.boolean :work_package_processed, default: false, index: true
      t.boolean :work_package_prioritized, default: false, index: true
      t.boolean :work_package_scheduled, default: false, index: true
      t.index :all
    end
  end
end
