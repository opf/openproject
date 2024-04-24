class CreateMeetingAgendaItemJournals < ActiveRecord::Migration[7.0]
  # rubocop:disable Rails/CreateTableWithTimestamps(RuboCop)
  def change
    create_table :meeting_agenda_item_journals do |t|
      t.integer :journal_id
      t.integer :agenda_item_id
      t.integer :author_id
      t.string :title
      t.text :notes
      t.integer :position
      t.integer :duration_in_minutes
      t.datetime :start_time
      t.datetime :end_time
      t.integer :work_package_id
    end
  end
  # rubocop:enable Rails/CreateTableWithTimestamps(RuboCop)
end
