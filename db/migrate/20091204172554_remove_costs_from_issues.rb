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

    # create a temporary admin user
    u = User.new(:firstname => "Automatic", :lastname => "Migration")
    u.admin = true
    User.current = u
    
    # update the new denormalized columns
    transaction do
      cache do
        Issue.all.each{|i| i.update_costs!}
      end
    end
    
    # clean up after me
    User.current = User.anonymous

  end
end
