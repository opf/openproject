class AddParentIdToEnumerations < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :parent_id, :integer, :null => true, :default => nil
  end

  def self.down
    remove_column :enumerations, :parent_id
  end
end
