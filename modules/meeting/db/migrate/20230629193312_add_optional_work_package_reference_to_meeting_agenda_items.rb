class AddOptionalWorkPackageReferenceToMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    add_reference :meeting_agenda_items, :work_package, foreign_key: true
  end
end