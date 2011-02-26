class ChangeAuthSourcesAccountPasswordLimit < ActiveRecord::Migration
  def self.up
    change_column :auth_sources, :account_password, :string, :limit => nil, :default => ''
  end

  def self.down
    change_column :auth_sources, :account_password, :string, :limit => 60, :default => ''
  end
end
