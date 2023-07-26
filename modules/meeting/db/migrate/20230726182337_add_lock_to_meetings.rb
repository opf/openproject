class AddLockToMeetings < ActiveRecord::Migration[5.1]
  def change
    add_column :meetings, :agenda_items_locked, :boolean, default: false
  end
end
