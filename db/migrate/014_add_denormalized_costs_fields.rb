class AddDenormalizedCostsFields < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2, :null => true
    
    add_column :time_entries, :costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :time_entries, :rate_id, :integer
    
    add_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :cost_entries, :rate_id, :integer
    
    add_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
    add_column :issues, :material_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
    add_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
    
    # create a temporary admin user
    u = User.new(:firstname => "Automatic", :lastname => "Migration")
    u.admin = true
    User.current = u
    
    # update the new denormalized columns
    transaction do
      cache do
        CostEntry.all.each {|e| e.update_costs!}
        TimeEntry.all.each {|e| e.update_costs!}
        
        Issue.all.each{|i| i.update_costs!}
      end
    end
    
    # clean up after me
    User.current = User.anonymous
  end
  
  def self.down
    remove_column :time_entries, :overridden_costs

    remove_column :time_entries, :costs
    remove_column :time_entries, :rate_id

    remove_column :cost_entries, :costs
    remove_column :cost_entries, :rate_id
    
    remove_column :issues, :labor_costs
    remove_column :issues, :material_costs
  end
end
