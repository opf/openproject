class AddItemTypeToMeetingAgendaItems < ActiveRecord::Migration[7.0]
  def change
    add_column :meeting_agenda_items, :item_type, :integer, limit: 1, default: 0
  end
end
