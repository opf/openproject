class ChangeNotificationSettingsStartDateDueDateAndOverdueDurationUnitToDays < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.change_default :start_date, from: 24, to: 1
      t.change_default :due_date, from: 24, to: 1
    end

    reversible do |dir|
      dir.up do
        update_durations_from_hours_to_days
      end

      dir.down do
        update_durations_from_days_to_hours
      end
    end
  end

  def update_durations_from_hours_to_days
    execute <<~SQL.squish
      UPDATE
        notification_settings
      SET
        start_date = CASE WHEN start_date IS NOT NULL THEN start_date / 24 END,
        due_date = CASE WHEN due_date IS NOT NULL THEN due_date / 24 END,
        overdue = CASE WHEN overdue IS NOT NULL THEN overdue / 24 END
    SQL
  end

  def update_durations_from_days_to_hours
    execute <<~SQL.squish
      UPDATE
        notification_settings
      SET
        start_date = CASE WHEN start_date IS NOT NULL THEN start_date * 24 END,
        due_date = CASE WHEN due_date IS NOT NULL THEN due_date * 24 END,
        overdue = CASE WHEN overdue IS NOT NULL THEN overdue * 24 END
    SQL
  end
end
