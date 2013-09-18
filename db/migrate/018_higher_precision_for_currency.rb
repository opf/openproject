class HigherPrecisionForCurrency < ActiveRecord::Migration

  def initialize
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  def self.up
    transaction do
      change_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 4
      change_column :cost_entries, :overridden_costs, :decimal, :precision => 15, :scale => 4

      change_column :time_entries, :costs, :decimal, :precision => 15, :scale => 4
      change_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 4

      if @issues_table_exists
        change_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
        change_column :issues, :material_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
        change_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 4, :null => false, :default => 0.0000
      end

      change_column :labor_budget_items, :budget, :decimal, :precision => 15, :scale => 4
      change_column :material_budget_items, :budget, :decimal, :precision => 15, :scale => 4

      change_column :rates, :rate, :decimal, :precision => 15, :scale => 4, :null => false
    end

    u = User.system

    # update the new denormalized columns
    transaction do
      cache do
        u.run_given do
          CostEntry.all.each {|e| e.update_costs!}
          TimeEntry.all.each {|e| e.update_costs!}

          Issue.all.each{|i| i.update_costs!} if @issue_table_exists
        end
      end
    end
  end

  def self.down
    transaction do
      change_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 2
      change_column :cost_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2

      change_column :time_entries, :costs, :decimal, :precision => 15, :scale => 2
      change_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2

      if @issues_table_exists
        change_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00
        change_column :issues, :material_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00
        change_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.00
      end

      change_column :labor_budget_items, :budget, :decimal, :precision => 15, :scale => 2
      change_column :material_budget_items, :budget, :decimal, :precision => 15, :scale => 2

      change_column :rates, :rate, :decimal, :precision => 15, :scale => 2, :null => false
    end
  end
end
