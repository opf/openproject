class PrimaryKeyForGroupsUsers < ActiveRecord::Migration
  def self.up
    add_column :group_user, :id, :primary_key
  end

  def self.down
    remove_column :group_user, :id
  end
end
