class AddPermissionInheritance < ActiveRecord::Migration
  def self.up
    add_column :groups_users, :membership_type, :string, :default => 'default'
    add_column :member_roles, :membership_type, :string, :default => 'default'
    
    GroupUser.all.update_attribute!(:membership_type => "controller")
    MemberRole.all.update_attribute!(:membership_type => "controller")
  end
  
  def self.down
    remove_column :groups_users, :membership_type
    remove_column :member_roles, :membership_type
  end
end
