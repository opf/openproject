class CreateProjectsTrackers < ActiveRecord::Migration
  def self.up
    create_table :projects_trackers, :id => false do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :tracker_id, :integer, :default => 0, :null => false
    end
    add_index :projects_trackers, :project_id, :name => :projects_trackers_project_id
    
    # Associates all trackers to all projects (as it was before)
    tracker_ids = Tracker.find(:all).collect(&:id)
    Project.find(:all).each do |project|
      project.tracker_ids = tracker_ids
    end
  end

  def self.down
    drop_table :projects_trackers
  end
end
