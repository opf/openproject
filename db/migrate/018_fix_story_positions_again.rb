class FixStoryPositionsAgain < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Story.find(:all, :conditions => "parent_id is NULL", :order => "project_id ASC, fixed_version_id ASC, position ASC").each_with_index do |s,i|
        s.position=i+1
        s.save!
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
