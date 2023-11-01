class AddItemTypeToMeetingAgendaItemJournal < ActiveRecord::Migration[7.0]
  def change
    add_column :meeting_agenda_item_journals, :item_type, :integer, limit: 1

    Journal::MeetingAgendaItemJournal
      .where.not(work_package_id: nil)
      .or(Journal::MeetingAgendaItemJournal.where(title: nil))
      .update_all(item_type: :work_package)

    Journal::MeetingAgendaItemJournal
      .where(item_type: nil)
      .update_all(item_type: :simple)
  end
end
