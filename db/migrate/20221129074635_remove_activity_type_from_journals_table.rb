class RemoveActivityTypeFromJournalsTable < ActiveRecord::Migration[7.0]
  def up
    remove_column :journals, :activity_type
  end

  def down
    add_column :journals, :activity_type, :string

    execute <<-SQL.squish
      UPDATE
        journals
      SET
        activity_type =
          CASE
          WHEN journable_type = 'Attachment' THEN 'attachments'
          WHEN journable_type = 'Budget' THEN 'budgets'
          WHEN journable_type = 'Changeset' THEN 'changesets'
          WHEN journable_type = 'Document' THEN 'documents'
          WHEN journable_type = 'Meeting' THEN 'meetings'
          WHEN journable_type = 'Message' THEN 'messages'
          WHEN journable_type = 'News' THEN 'news'
          WHEN journable_type = 'TimeEntry' THEN 'time_entries'
          WHEN journable_type = 'WikiContent' THEN 'wiki_edits'
          WHEN journable_type = 'WorkPackage' THEN 'work_packages'
          END
      WHERE journable_type != 'MeetingContent'
    SQL

    execute <<-SQL.squish
      UPDATE
        journals
      SET
        activity_type =
          CASE
          WHEN meeting_contents.type = 'MeetingMinutes' THEN 'meeting_minutes'
          WHEN meeting_contents.type = 'MeetingAgenda' THEN 'meeting_agenda'
          ELSE 'meetings'
          END
      FROM meeting_contents
      WHERE journable_type = 'MeetingContent'
        AND journable_id = meeting_contents.id
    SQL
  end
end
