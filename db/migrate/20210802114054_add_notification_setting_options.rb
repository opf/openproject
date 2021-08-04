class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    add_notification_settings_options
    update_notified_events

    # TODO: add index to all boolean fields
  end

  def add_notification_settings_options
    change_table :notification_settings, bulk: true do |t|
      t.boolean :work_package_commented, default: false
      t.boolean :work_package_created, default: false
      t.boolean :work_package_processed, default: false
      t.boolean :work_package_prioritized, default: false
    end
  end

  def update_notified_events
    event_types = %w(work_package_added work_package_updated work_package_note_added status_updated work_package_priority_updated)

    # rubocop:disable Rails/WhereExists
    # The Setting.exists? method is overwritten
    reversible do |dir|
      dir.up do
        Setting.notified_events = Setting.notified_events - event_types if Setting.where(name: 'notified_events').exists?
      end

      dir.down do
        Setting.notified_events = Setting.notified_events + event_types if Setting.where(name: 'notified_events').exists?
      end
    end
    # rubocop:enable Rails/WhereExists
  end
end
