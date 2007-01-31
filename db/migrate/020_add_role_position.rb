class AddRolePosition < ActiveRecord::Migration
  def self.up
    add_column :roles, :position, :integer, :default => 1, :null => false
    Role.find(:all).each_with_index {|role, i| role.update_attribute(:position, i+1)}
  end

  def self.down
    remove_column :roles, :position
  end
end
