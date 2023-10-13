class AddItemTypeToMeetingAgendaItemJournal < ActiveRecord::Migration[7.0]
  def change
    add_column :meeting_agenda_item_journals, :item_type, :integer, limit: 1
  end
end
