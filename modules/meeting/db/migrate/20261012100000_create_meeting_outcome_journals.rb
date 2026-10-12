# frozen_string_literal: true

class CreateMeetingOutcomeJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_outcome_journals do |t|
      t.integer :journal_id, null: false
      t.bigint :outcome_id, null: false
      t.bigint :meeting_agenda_item_id
      t.bigint :work_package_id
      t.integer :kind, null: false
      t.text :notes
    end

    add_index :meeting_outcome_journals,
              %i[journal_id outcome_id],
              unique: true,
              name: :idx_meeting_outcome_journals_journal_outcome
  end
end
