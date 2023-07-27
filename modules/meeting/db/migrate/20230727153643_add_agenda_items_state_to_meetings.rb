class AddAgendaItemsStateToMeetings < ActiveRecord::Migration[5.1]
  def change
    remove_column :meetings, :agenda_items_locked
    add_column :meetings, :agenda_items_state, :integer, default: 0
  end
end
