class AddPresenterToMeeting < ActiveRecord::Migration[7.1]
  def change
    add_reference :meeting_agenda_items, :presenter, type: :bigint, foreign_key: { to_table: :users }, index: true
    add_reference :meeting_agenda_item_journals, :presenter, type: :bigint, foreign_key: { to_table: :users }, index: true
  end
end
