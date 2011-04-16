class ChangeJournalDetailsValuesToText < ActiveRecord::Migration
  def self.up
    change_column :journal_details, :old_value, :text
    change_column :journal_details, :value, :text
  end

  def self.down
    change_column :journal_details, :old_value, :string
    change_column :journal_details, :value, :string
  end
end
