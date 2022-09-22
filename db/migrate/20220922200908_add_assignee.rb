class AddAssignee < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.column :assignee, :boolean, default: false, null: false
      t.column :responsible, :boolean, default: false, null: false
    end

    reversible do |change|
      change.up do
        NotificationSetting.where(involved: true).update_all(assignee: true, responsible: true)
        remove_column :notification_settings, :involved, :boolean
      end

      change.down do
        add_column :notification_settings, :involved, :boolean
        NotificationSetting.where(assignee: true).or(NotificationSetting.where(responsible: true)).update_all(involved: true)
      end
    end
  end
end
