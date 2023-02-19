class AddLoggedByIdToTimeEntries < ActiveRecord::Migration[7.0]
  def change
    add_reference :time_entries, :logged_by, foreign_key: { to_table: :users }, index: true
  end
end
