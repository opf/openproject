class AddStateToMeetingJournal < ActiveRecord::Migration[7.1]
  def change
    add_column :meeting_journals, :state, :integer, default: 0, null: false
  end
end
