class AddTsvColumnsToAttachments < ActiveRecord::Migration[5.0]
  def up
    if OpenProject::Database.allows_tsv?
      add_column :attachments, :fulltext_tsv, :tsvector
      add_column :attachments, :file_tsv, :tsvector

      add_index :attachments, :fulltext_tsv, using: "gin"
      add_index :attachments, :file_tsv, using: "gin"
    else
      warn "Your installation does not support full-text search features. Better use PostgreSQL in version 9.6 or higher."
    end

  end

  def down
    if OpenProject::Database.allows_tsv?
      remove_index :attachments, :fulltext_tsv
      remove_index :attachments, :file_tsv

      remove_column :attachments, :fulltext_tsv
      remove_column :attachments, :file_tsv
    end
  end
end
