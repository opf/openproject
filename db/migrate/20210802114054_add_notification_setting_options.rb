class AddNotificationSettingOptions < ActiveRecord::Migration[6.1]
  def change
    add_notification_settings_options
    update_notified_events
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
      t.index :all
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
