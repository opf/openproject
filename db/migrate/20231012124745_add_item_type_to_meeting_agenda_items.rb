class AddItemTypeToMeetingAgendaItems < ActiveRecord::Migration[7.0]
  def change
    add_column :meeting_agenda_items, :item_type, :integer, limit: 1, default: 0

    MeetingAgendaItem
      .where.not(work_package_id: nil)
      .or(MeetingAgendaItem.where(title: nil))
      .update_all(item_type: :work_package)
  end
end
