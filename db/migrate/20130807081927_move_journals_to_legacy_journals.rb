class MoveJournalsToLegacyJournals < ActiveRecord::Migration
  def up
    rename_table :journals, :legacy_journals
  end

  def down
    rename_table :legacy_journals, :journals
  end
end
