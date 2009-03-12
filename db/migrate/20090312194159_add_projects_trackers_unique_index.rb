class AddProjectsTrackersUniqueIndex < ActiveRecord::Migration
  def self.up
    remove_duplicates
    add_index :projects_trackers, [:project_id, :tracker_id], :name => :projects_trackers_unique, :unique => true
  end

  def self.down
    remove_index :projects_trackers, :name => :projects_trackers_unique
  end

  # Removes duplicates in projects_trackers table
  def self.remove_duplicates
    Project.find(:all).each do |project|
      ids = project.trackers.collect(&:id)
      unless ids == ids.uniq
        project.trackers.clear
        project.tracker_ids = ids.uniq
      end
    end
  end
end
