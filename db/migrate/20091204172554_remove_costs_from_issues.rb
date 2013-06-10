class RemoveCostsFromIssues < ActiveRecord::Migration
  def self.up
    remove_column :issues, :labor_costs
    remove_column :issues, :material_costs
    remove_column :issues, :overall_costs
  end

  def self.down
    add_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0
    add_column :issues, :material_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0
    add_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0

    u = User.system

    # update the new denormalized columns
    transaction do
      cache do
        u.run_given do
          Issue.all.each{|i| i.update_costs!}
        end
      end
    end
  end
end
