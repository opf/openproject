class AddCostTypesDefault < ActiveRecord::Migration
  def self.up
    add_column :cost_types, :default, :boolean,:default => false, :null => false
  end
  
  def self.down
    remove_column :cost_types, :default
  end
end