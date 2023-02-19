class AddStartDateDueDateAndOverdueToNotificationSettings < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.column :start_date, :integer, default: 24
      t.column :due_date, :integer, default: 24
      t.column :overdue, :integer, default: nil
    end
  end
end
