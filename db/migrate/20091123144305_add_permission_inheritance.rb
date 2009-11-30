class AddPermissionInheritance < ActiveRecord::Migration
  def self.up
    add_column :groups_users, :membership_type, :string, :null => false, :default => 'controller'
    add_column :member_roles, :membership_type, :string, :null => false, :default => 'controller'
    
    change_column :groups_users, :membership_type, :string, :null => false, :default => 'default'
    change_column :member_roles, :membership_type, :string, :null => false, :default => 'default'
  end
  
  def self.down
    remove_column :groups_users, :membership_type
    remove_column :member_roles, :membership_type
  end
end
