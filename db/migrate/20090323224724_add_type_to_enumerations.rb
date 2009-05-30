class AddTypeToEnumerations < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :type, :string
  end

  def self.down
    remove_column :enumerations, :type
  end
end
