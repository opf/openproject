class RemoveCostsFromIssues < ActiveRecord::Migration

  def initialize
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  def self.up
    if @issues_table_exists
      remove_column :issues, :labor_costs
      remove_column :issues, :material_costs
      remove_column :issues, :overall_costs
    end
  end

  def self.down
    if @issues_table_exists
      add_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0
      add_column :issues, :material_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0
      add_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0
    end

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
