class AddLockingToMeeting < ActiveRecord::Migration[7.0]
  def change
    add_column :meetings, :lock_version, :integer, default: 0, null: false
    add_column :meeting_agenda_items, :lock_version, :integer, default: 0, null: false
  end
end
