class AddChangesBranch < ActiveRecord::Migration
  def self.up
    add_column :changes, :branch, :string
  end

  def self.down
    remove_column :changes, :branch
  end
end
