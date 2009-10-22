class DenormalizeSpentOnOfCostEntries < ActiveRecord::Migration
  def self.up
    add_column :cost_entries, :tyear, :integer, :null => true
    add_column :cost_entries, :tmonth, :integer, :null => true
    add_column :cost_entries, :tweek, :integer, :null => true
  
    # create a temporary admin user
    u = User.new(:firstname => "Automatic", :lastname => "Migration")
    u.admin = true
    User.current = u
    
    CostEntry.all.each do |e|
      e.spent_on = e.spent_on
      e.save!
    end
  
    change_column :cost_entries, :tyear, :integer, :null => false
    change_column :cost_entries, :tmonth, :integer, :null => false
    change_column :cost_entries, :tweek, :integer, :null => false
  end
  
  def self.down
    remove_column :cost_entries, :tyear
    remove_column :cost_entries, :tmonth
    remove_column :cost_entries, :tweek
  end
end