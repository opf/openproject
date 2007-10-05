class AddEnumerationsIsDefault < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :is_default, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :enumerations, :is_default
  end
end
