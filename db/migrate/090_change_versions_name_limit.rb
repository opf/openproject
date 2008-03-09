class ChangeVersionsNameLimit < ActiveRecord::Migration
  def self.up
    change_column :versions, :name, :string, :limit => nil
  end

  def self.down
    change_column :versions, :name, :string, :limit => 30
  end
end
