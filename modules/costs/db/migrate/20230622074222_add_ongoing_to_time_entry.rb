class AddOngoingToTimeEntry < ActiveRecord::Migration[7.0]
  def change
    change_table :time_entries do |t|
      t.boolean :ongoing, null: false, default: false, index: true
    end

    add_index :time_entries, %i[user_id ongoing], unique: true, where: "ongoing = true"

    change_column_null :time_entries, :activity_id, true
    change_column_null :time_entries, :hours, true

    change_column_null :time_entry_journals, :activity_id, true
    change_column_null :time_entry_journals, :hours, true
  end
end
