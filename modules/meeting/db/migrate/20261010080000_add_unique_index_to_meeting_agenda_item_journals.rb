# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/utils")

class AddUniqueIndexToMeetingAgendaItemJournals < ActiveRecord::Migration[8.1]
  include Migration::Utils

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
    remove_index_on :meeting_agenda_item_journals,
                    :idx_meeting_agenda_item_journals_journal_item,
                    %w[journal_id agenda_item_id]
  end
end
