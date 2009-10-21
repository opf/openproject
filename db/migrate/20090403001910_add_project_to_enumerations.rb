class AddProjectToEnumerations < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :project_id, :integer, :null => true, :default => nil
    add_index :enumerations, :project_id
  end

  def self.down
    remove_index :enumerations, :project_id
    remove_column :enumerations, :project_id
  end
end
