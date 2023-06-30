class AddInputOutputToMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    add_column :meeting_agenda_items, :input, :text
    add_column :meeting_agenda_items, :output, :text
  end
end