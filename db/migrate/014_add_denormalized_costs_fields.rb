class AddDenormalizedCostsFields < ActiveRecord::Migration

  def initialize
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  def self.up
    add_column :time_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2, :null => true

    add_column :time_entries, :costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :time_entries, :rate_id, :integer

    add_column :cost_entries, :costs, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :cost_entries, :rate_id, :integer

    if @issues_table_exists
      add_column :issues, :labor_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
      add_column :issues, :material_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
      add_column :issues, :overall_costs, :decimal, :precision => 15, :scale => 2, :null => false, :default => 0.0
    end

    #necessary because the User table might have been changed
    User.reset_column_information
    #Users have associated custom fields which are also changed during migrations
    CustomField.reset_column_information
    u = User.system

    # update the new denormalized columns
    transaction do
      cache do
        u.run_given do
          CostEntry.all.each {|e| e.update_costs!}
          TimeEntry.all.each {|e| e.update_costs!}

          Issue.all.each{|i| i.update_costs!} if @issues_table_exists
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

    if @issues_table_exists
      remove_column :issues, :labor_costs
      remove_column :issues, :material_costs
      remove_column :issues, :overall_costs
    end
  end
end
