class HigherPrecisionForCurrency < ActiveRecord::Migration
  def self.up
    transaction do
      change_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 4
      change_column :cost_entries, :overridden_costs, :decimal, :precision => 15, :scale => 4

      change_column :time_entries, :costs, :decimal, :precision => 15, :scale => 4
      change_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 4
      
      change_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
      change_column :issues, :material_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
      change_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
      
      change_column :labor_budget_items, :budget, :decimal, :precision => 15, :scale => 4
      change_column :material_budget_items, :budget, :decimal, :precision => 15, :scale => 4
      
      change_column :rates, :rate, :decimal, :precision => 15, :scale => 4, :null => false
    end
    
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
    
    User.current = nil
  end
  
  def self.down
    transaction do
      change_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 2
      change_column :cost_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2

      change_column :time_entries, :costs, :decimal, :precision => 15, :scale => 2
      change_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2
      
      change_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00
      change_column :issues, :material_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00
      change_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00

      change_column :labor_budget_items, :budget, :decimal, :precision => 15, :scale => 2
      change_column :material_budget_items, :budget, :decimal, :precision => 15, :scale => 2
      
      change_column :rates, :rate, :decimal, :precision => 15, :scale => 2, :null => false
    end
  end
end
