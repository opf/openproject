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

    u = User.system

    # update the new denormalized columns
    transaction do
      cache do
        u.run_given do
          CostEntry.all.each {|e| e.update_costs!}
          TimeEntry.all.each {|e| e.update_costs!}

          Issue.all.each{|i| i.update_costs!}
        end
      end
    end
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
