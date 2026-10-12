# frozen_string_literal: true

class BackfillUnjournaledMeetingAgendaItems < ActiveRecord::Migration[8.1]
  # Agenda items that are in no journal of their meeting were never journaled: they predate agenda item journaling,
  # were copied along with their meeting or were changed by code that did not journal the meeting.
  # They are added with their current values to every journal that was still valid when they were created.
  # Items that appear in any journal of their meeting are left alone.
  def up
    execute(<<~SQL.squish)
      INSERT INTO meeting_agenda_item_journals
        (journal_id, agenda_item_id, author_id, title, notes, position, duration_in_minutes, work_package_id,
         item_type, presenter_id)
      SELECT
        journals.id,
        meeting_agenda_items.id,
        meeting_agenda_items.author_id,
        meeting_agenda_items.title,
        meeting_agenda_items.notes,
        meeting_agenda_items.position,
        meeting_agenda_items.duration_in_minutes,
        meeting_agenda_items.work_package_id,
        meeting_agenda_items.item_type,
        meeting_agenda_items.presenter_id
      FROM journals
      JOIN meeting_agenda_items ON meeting_agenda_items.meeting_id = journals.journable_id
      WHERE journals.journable_type = 'Meeting'
        AND meeting_agenda_items.created_at < COALESCE(upper(journals.validity_period), 'infinity')
        AND NOT EXISTS (
          SELECT 1
          FROM meeting_agenda_item_journals journaled_items
          JOIN journals meeting_journals ON meeting_journals.id = journaled_items.journal_id
          WHERE journaled_items.agenda_item_id = meeting_agenda_items.id
            AND meeting_journals.journable_type = 'Meeting'
            AND meeting_journals.journable_id = meeting_agenda_items.meeting_id
        )
    SQL
  end

  def down; end
end
