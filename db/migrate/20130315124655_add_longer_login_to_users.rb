class AddLongerLoginToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.change "login", :string, :limit => 256, :default => "", :null => false
    end
  end

  def self.down
    change_table :users do |t|
      t.change "login", :string, :limit => 30, :default => "", :null => false
    end
  end
end
