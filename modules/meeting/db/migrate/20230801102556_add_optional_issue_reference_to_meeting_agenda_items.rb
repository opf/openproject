class AddOptionalIssueReferenceToMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    remove_reference :meeting_agenda_items, :work_package
    remove_column :meeting_agenda_items, :input, :text
    remove_column :meeting_agenda_items, :output, :text
    add_reference :meeting_agenda_items, :work_package_issue, foreign_key: true
  end
end
