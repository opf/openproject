# frozen_string_literal: true

class CreateMeetingSectionJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_section_journals do |t|
      t.integer :journal_id, null: false
      t.bigint :section_id, null: false
      t.string :title
      t.integer :position
      t.boolean :backlog, default: false, null: false
    end

    add_index :meeting_section_journals,
              %i[journal_id section_id],
              unique: true,
              name: :idx_meeting_section_journals_journal_section

    add_column :meeting_agenda_item_journals, :meeting_section_id, :bigint
  end
end
