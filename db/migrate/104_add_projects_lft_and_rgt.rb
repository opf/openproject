class AddProjectsLftAndRgt < ActiveRecord::Migration
  def self.up
    add_column :projects, :lft, :integer
    add_column :projects, :rgt, :integer
  end

  def self.down
    remove_column :projects, :lft
    remove_column :projects, :rgt
  end
end
