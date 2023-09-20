class AddWorkPackageToMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    add_reference :meeting_agenda_items, :work_package, index: true
  end
end
