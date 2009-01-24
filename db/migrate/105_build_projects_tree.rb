class BuildProjectsTree < ActiveRecord::Migration
  def self.up
    Project.rebuild!
  end

  def self.down
  end
end
