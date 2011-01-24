class FixPositions < ActiveRecord::Migration
  def self.up
    errors = 0
    Issue.find(:all, :conditions => "subject is NULL").each do |issue|
      errors += 1
      puts "Issue #{issue.id} does not have a subject"
    end
    raise "Errors found in your database, aborting migration" if errors > 0

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
