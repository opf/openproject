class PrimaryKeyForGroupsUsers < ActiveRecord::Migration
  def self.up
    add_column :group_users, :id, :primary_key
  end

  def self.down
    remove_column :group_users, :id
  end
end
