class AddResponsibleToMeeting < ActiveRecord::Migration[7.1]
  def change
    add_reference :meeting_agenda_items, :responsible, type: :bigint, foreign_key: { to_table: :users }, index: true
    add_reference :meeting_agenda_item_journals, :responsible, type: :bigint, foreign_key: { to_table: :users }, index: true
  end
end
