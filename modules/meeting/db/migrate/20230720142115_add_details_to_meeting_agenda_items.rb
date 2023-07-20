class AddDetailsToMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    add_column :meeting_agenda_items, :details, :text
  end
end