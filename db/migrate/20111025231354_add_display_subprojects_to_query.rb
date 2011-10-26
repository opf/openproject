class AddDisplaySubprojectsToQuery < ActiveRecord::Migration
  def self.up
    add_column :queries, :display_subprojects, :boolean
  end

  def self.down
    remove_column :queries, :display_subprojects
  end
end
