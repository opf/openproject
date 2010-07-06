class ChangeChangesPathLengthLimit < ActiveRecord::Migration
  def self.up
    change_column :changes, :path, :text, :null => false
    change_column :changes, :from_path, :text
  end

  def self.down
    change_column :changes, :path, :string, :default => "", :null => false
    change_column :changes, :from_path, :string
  end
end
