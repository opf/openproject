class FixAttachableJournals < ActiveRecord::Migration[6.0]
  # Adds attachable_journals to all journals where the
  # attachment was created before the journal as long as there
  # is no attachable_journal associated to the journal yet.
  #
  # This does not fix journals where the attachment has been deleted in the meantime as
  # we no longer have the necessary information to recreate the journals.
  def up
    statement = <<~SQL
      WITH
        existing_attachments AS (
          SELECT
            id,
            created_at,
            file,
            container_id,
            container_type,
            author_id
          FROM attachments),
        existing_attachable_journals AS (
          SELECT
            journals.id journal_id,
            attachable_journals.attachment_id
          FROM journals
          LEFT OUTER JOIN attachable_journals ON journals.id = attachable_journals.journal_id
          LEFT OUTER JOIN attachments ON attachable_journals.attachment_id = attachments.id)

      INSERT INTO attachable_journals (journal_id, attachment_id, filename)
      SELECT
        journals.id journal_id,
        existing_attachments.id attachment_id,
        existing_attachments.file filename
      FROM journals
      JOIN existing_attachments
        ON journals.created_at >= existing_attachments.created_at
        AND journals.user_id = existing_attachments.author_id
        AND journals.journable_id = existing_attachments.container_id
        AND journals.journable_type = existing_attachments.container_type
      LEFT OUTER JOIN existing_attachable_journals
        ON existing_attachments.id = existing_attachable_journals.attachment_id
        AND journals.id = existing_attachable_journals.journal_id
      WHERE attachment_id IS NULL
    SQL

    ActiveRecord::Base.connection.execute statement
  end

  # Does not require a down statement as a bug is fixed.
end
