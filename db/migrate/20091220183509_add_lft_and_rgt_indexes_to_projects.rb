class AddLftAndRgtIndexesToProjects < ActiveRecord::Migration
  def self.up
    add_index :projects, :lft
    add_index :projects, :rgt
  end

  def self.down
    remove_index :projects, :lft
    remove_index :projects, :rgt
  end
end
