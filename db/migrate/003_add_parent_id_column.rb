class AddParentIdColumn < ActiveRecord::Migration
  def self.up
    add_column :items, :parent_id, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :items, :parent_id
  end
end
