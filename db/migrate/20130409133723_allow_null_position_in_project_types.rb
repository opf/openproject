class AllowNullPositionInProjectTypes < ActiveRecord::Migration
  def self.up
    change_column :timelines_project_types, :position, :integer, :default => 1, :null => true
  end

  def self.down
    change_column :timelines_project_types, :position, :integer, :default => 1, :null => false
  end
end
