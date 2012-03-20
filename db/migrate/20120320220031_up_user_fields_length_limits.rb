class UpUserFieldsLengthLimits < ActiveRecord::Migration
  def self.up
    change_column :users, :login, :string, :limit => nil
    change_column :users, :mail, :string, :limit => nil
    change_column :users, :firstname, :string, :limit => nil
    change_column :users, :lastname, :string, :limit => nil
  end

  def self.down
    change_column :users, :login, :string, :limit => 30
    change_column :users, :mail, :string, :limit => 60
    change_column :users, :firstname, :string, :limit => 30
    change_column :users, :lastname, :string, :limit => 30
  end
end
