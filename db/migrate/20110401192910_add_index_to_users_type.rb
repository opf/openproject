class AddIndexToUsersType < ActiveRecord::Migration
  def self.up
    add_index :users, :type
  end

  def self.down
    remove_index :users, :type
  end
end
