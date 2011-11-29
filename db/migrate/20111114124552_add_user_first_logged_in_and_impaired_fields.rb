class AddUserFirstLoggedInAndImpairedFields < ActiveRecord::Migration
  def self.up
    add_column :users, :first_login, :boolean, :null => false, :default => true
    add_column :user_preferences, :impaired, :boolean, :default => false
  end

  def self.down
    remove_column :users, :first_login
    remove_column :user_preferences, :impaired
  end
end
