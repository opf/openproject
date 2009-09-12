class PopulateUsersType < ActiveRecord::Migration
  def self.up
    Principal.update_all("type = 'User'", "type IS NULL")
  end

  def self.down
  end
end
