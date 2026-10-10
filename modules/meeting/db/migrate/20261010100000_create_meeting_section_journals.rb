# frozen_string_literal: true

class CreateMeetingSectionJournals < ActiveRecord::Migration[8.1]
  def up
    create_table :meeting_section_journals do |t|
      t.integer :journal_id, null: false
      t.bigint :section_id, null: false
      t.string :title
      t.integer :position, null: false
      t.boolean :backlog, default: false, null: false
    end

    add_index :meeting_section_journals,
              %i[journal_id section_id],
              unique: true,
              name: :idx_meeting_section_journals_journal_section

    add_column :meeting_agenda_item_journals, :meeting_section_id, :bigint

    backfill_section_journals
    backfill_agenda_item_journals
  end

  def down
    remove_column :meeting_agenda_item_journals, :meeting_section_id
    drop_table :meeting_section_journals
  end

  private

  # Historic values are unknown, so every journal gets the current values of the sections that existed by then.
  def backfill_section_journals
    execute(<<~SQL.squish)
      INSERT INTO meeting_section_journals (journal_id, section_id, title, position, backlog)
      SELECT journals.id, meeting_sections.id, meeting_sections.title, meeting_sections.position, meeting_sections.backlog
      FROM journals
      JOIN meeting_sections ON meeting_sections.meeting_id = journals.journable_id
      WHERE journals.journable_type = 'Meeting'
        AND meeting_sections.created_at <= journals.updated_at
    SQL
  end

  # Agenda item journals get the item's current section, but only if the same journal records that section.
  # Otherwise the journal would place the item in a section that, according to that journal, did not exist:
  # one created after the journal, or one of another meeting the item has moved to since.
  # Such agenda item journals keep a NULL section.
  #
  # presenter_id has never been journaled. Without the backfill, the next save of any meeting with presenters
  # would create a journal.
  def backfill_agenda_item_journals
    execute(<<~SQL.squish)
      UPDATE meeting_agenda_item_journals
      SET
        presenter_id = meeting_agenda_items.presenter_id,
        meeting_section_id = CASE
          WHEN EXISTS (
            SELECT 1
            FROM meeting_section_journals
            WHERE meeting_section_journals.journal_id = meeting_agenda_item_journals.journal_id
              AND meeting_section_journals.section_id = meeting_agenda_items.meeting_section_id
          ) THEN meeting_agenda_items.meeting_section_id
        END
      FROM meeting_agenda_items
      WHERE meeting_agenda_items.id = meeting_agenda_item_journals.agenda_item_id
    SQL
  end
end
