class AddActiveFieldToEnumerations < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :active, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :enumerations, :active
  end
end
