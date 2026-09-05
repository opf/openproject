# rubocop:disable Rails/SquishedSQLHeredocs
# frozen_string_literal: true

class MigrateClassicMeetings < ActiveRecord::Migration[8.0]
  def up
    # Create default sections for meetings that don't have one
    execute <<~SQL
      INSERT INTO meeting_sections (meeting_id, title, position, created_at, updated_at)
      SELECT m.id, '', 1, NOW(), NOW()
      FROM meetings m
      LEFT JOIN meeting_sections ms ON ms.meeting_id = m.id
      WHERE ms.id IS NULL;
    SQL

    # Migrate MeetingAgenda content to MeetingAgendaItem
    execute <<~SQL.squish
      INSERT INTO meeting_agenda_items (
        meeting_id,
        meeting_section_id,
        author_id,
        presenter_id,
        title,
        notes,
        position,
        created_at,
        updated_at
      )
      SELECT
        mc.meeting_id,
        ms.id,
        mc.author_id,
        mc.author_id,
        '#{I18n.t(:label_meeting_agenda)}',
        mc.text,
        1,
        mc.created_at,
        mc.updated_at
      FROM meeting_contents mc
      INNER JOIN meetings m ON m.id = mc.meeting_id
      INNER JOIN meeting_sections ms ON ms.meeting_id = m.id
      WHERE mc.type = 'MeetingAgenda';
    SQL

    # Migrate MeetingMinutes to MeetingOutcome
    execute <<~SQL.squish
      INSERT INTO meeting_outcomes (
        meeting_agenda_item_id,
        author_id,
        notes,
        created_at,
        updated_at
      )
      SELECT
        mai.id,
        mc.author_id,
        mc.text,
        mc.created_at,
        mc.updated_at
      FROM meeting_contents mc
      INNER JOIN meetings m ON m.id = mc.meeting_id
      INNER JOIN meeting_sections ms ON ms.meeting_id = m.id
      INNER JOIN meeting_agenda_items mai ON mai.meeting_id = m.id
      WHERE mc.type = 'MeetingMinutes';
    SQL

    # Close classic meetings that are in the past
    execute <<~SQL.squish
      UPDATE meetings
      SET state = 5
      WHERE type = 'Meeting'
      AND start_time < CURRENT_TIMESTAMP
    SQL

    # Remove STI column
    remove_column :meetings, :type
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
