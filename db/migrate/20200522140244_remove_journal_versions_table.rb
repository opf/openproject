require_relative './20190724093332_add_journal_versions_table'

class RemoveJournalVersionsTable < ActiveRecord::Migration[6.0]
  def up
    ::AddJournalVersionsTable.down
  end

  def down
    ::AddJournalVersionsTable.up
  end
end
