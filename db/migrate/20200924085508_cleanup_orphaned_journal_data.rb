class CleanupOrphanedJournalData < ActiveRecord::Migration[6.0]
  def up
    cleanup_orphaned_journals('attachable_journals')
    cleanup_orphaned_journals('customizable_journals')
    cleanup_orphaned_journals('attachment_journals')
    cleanup_orphaned_journals('changeset_journals')
    cleanup_orphaned_journals('message_journals')
    cleanup_orphaned_journals('news_journals')
    cleanup_orphaned_journals('wiki_content_journals')
    cleanup_orphaned_journals('work_package_journals')
  end

  # No down needed as this only cleans up data that should have been deleted anyway.

  private

  def cleanup_orphaned_journals(table)
    execute <<~SQL
      DELETE
      FROM
        #{table}
      WHERE
        #{table}.id IN (
          SELECT
            #{table}.id
          FROM
            #{table}
          LEFT OUTER JOIN
            journals
          ON
            journals.id = #{table}.journal_id
          WHERE
            journals.id IS NULL
        )
    SQL
  end
end
