class AddIndexOnIdentifierToProjects < ActiveRecord::Migration
  def self.up
    add_index :projects, :identifier
  end

  def self.down
    remove_index :projects, :identifier
  end
end
