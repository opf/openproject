require_relative './20190724093332_add_journal_versions_table'

# db/migrate/20200522140244_remove_journal_versions_table.rb
# incorrectly removes journal_versions
class RemoveJournalVersions < ActiveRecord::Migration[6.1]
  def up
    ::AddJournalVersionsTable.new.down
  end

  def down
    # Nothing to do
  end
end
