class AddJournalColumnsToTimeEntryJournals < ActiveRecord::Migration
  def change
    add_column :time_entry_journals, :overridden_costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :time_entry_journals, :costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :time_entry_journals, :rate_id, :integer
  end
end
