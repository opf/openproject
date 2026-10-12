# frozen_string_literal: true

class AddUniqueIndexToMeetingAgendaItemJournals < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL.squish)
      DELETE FROM meeting_agenda_item_journals
      USING meeting_agenda_item_journals newer
      WHERE meeting_agenda_item_journals.journal_id = newer.journal_id
        AND meeting_agenda_item_journals.agenda_item_id = newer.agenda_item_id
        AND meeting_agenda_item_journals.id < newer.id
    SQL

    add_index :meeting_agenda_item_journals,
              %i[journal_id agenda_item_id],
              unique: true,
              name: :idx_meeting_agenda_item_journals_journal_item
  end

  def down
    remove_index :meeting_agenda_item_journals, name: :idx_meeting_agenda_item_journals_journal_item
  end
end
