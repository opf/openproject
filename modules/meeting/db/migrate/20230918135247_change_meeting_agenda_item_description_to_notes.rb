class ChangeMeetingAgendaItemDescriptionToNotes < ActiveRecord::Migration[7.0]
  def change
    rename_column :meeting_agenda_items, :description, :notes
  end
end
