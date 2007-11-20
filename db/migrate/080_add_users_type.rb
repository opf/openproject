class AddUsersType < ActiveRecord::Migration
  def self.up
    add_column :users, :type, :string
    User.update_all "type = 'User'"
  end

  def self.down
    remove_column :users, :type
  end
end
