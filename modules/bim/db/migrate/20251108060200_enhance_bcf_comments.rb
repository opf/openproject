# frozen_string_literal: true

class EnhanceBcfComments < ActiveRecord::Migration[8.0]
  def change
    add_column :bcf_comments, :status, :string, limit: 50
    add_column :bcf_comments, :reactions, :jsonb, default: {}, null: false

    # Add indexes for querying
    add_index :bcf_comments, :status, name: 'idx_bcf_comments_status'

    # Add GIN index for reactions JSONB column for efficient querying
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE INDEX idx_bcf_comments_reactions ON bcf_comments USING GIN (reactions);
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP INDEX IF EXISTS idx_bcf_comments_reactions;
        SQL
      end
    end

    # Add check constraint for valid status values
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE bcf_comments
          ADD CONSTRAINT check_bcf_comment_status
          CHECK (status IS NULL OR status IN ('question', 'issue', 'suggestion', 'resolved', 'info'));
        SQL
      end

      dir.down do
        execute <<-SQL
          ALTER TABLE bcf_comments DROP CONSTRAINT IF EXISTS check_bcf_comment_status;
        SQL
      end
    end
  end
end
