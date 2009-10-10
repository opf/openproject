class FixUsersCustomValues < ActiveRecord::Migration
  def self.up
    CustomValue.update_all("customized_type = 'Principal'", "customized_type = 'User'")
  end

  def self.down
    CustomValue.update_all("customized_type = 'User'", "customized_type = 'Principal'")
  end
end
