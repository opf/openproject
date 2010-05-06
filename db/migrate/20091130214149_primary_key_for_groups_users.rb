class PrimaryKeyForGroupsUsers < ActiveRecord::Migration
  def self.up
    add_column :groups_users, :id, :primary_key
  end
  
  def self.down
    remove_column :groups_users, :id
  end
end
