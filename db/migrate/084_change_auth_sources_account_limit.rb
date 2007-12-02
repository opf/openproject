class ChangeAuthSourcesAccountLimit < ActiveRecord::Migration
  def self.up
    change_column :auth_sources, :account, :string
  end

  def self.down
    change_column :auth_sources, :account, :string, :limit => 60
  end
end
