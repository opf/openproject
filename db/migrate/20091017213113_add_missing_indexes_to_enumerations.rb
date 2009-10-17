class AddMissingIndexesToEnumerations < ActiveRecord::Migration
  def self.up
    add_index :enumerations, [:id, :type]
  end

  def self.down
    remove_index :enumerations, :column => [:id, :type]
  end
end
