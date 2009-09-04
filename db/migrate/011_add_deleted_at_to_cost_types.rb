class AddDeletedAtToCostTypes < ActiveRecord::Migration
  def self.up
    add_column :cost_types, :deleted_at, :timestamp,    :null => true
  end
  
  def self.down
    remove_column :deliverables, :deleted_at
  end
end