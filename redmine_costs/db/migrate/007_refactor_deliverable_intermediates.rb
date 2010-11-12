class RefactorDeliverableIntermediates < ActiveRecord::Migration
  def self.up
    add_column :deliverable_costs, :cost_type_id, :integer # , :null => false
    remove_column :deliverable_costs, :rate_id

    add_column :deliverable_hours, :user_id, :integer #, :null => false
    remove_column :deliverable_hours, :rate_id
  end
  
  def self.down
    add_column :deliverable_costs, :rate_id, :integer, :null => false
    remove_column :deliverable_costs, :cost_type_id

    add_column :deliveable_hours, :rate_id, :integer, :null => false
    remove_column :deliverable_hours, :user_id
  end
end
