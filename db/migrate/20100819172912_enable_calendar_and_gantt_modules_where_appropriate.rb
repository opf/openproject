class EnableCalendarAndGanttModulesWhereAppropriate < ActiveRecord::Migration
  def self.up
    EnabledModule.find(:all, :conditions => ["name = ?", 'issue_tracking']).each do |e|
      EnabledModule.create(:name => 'calendar', :project_id => e.project_id)
      EnabledModule.create(:name => 'gantt', :project_id => e.project_id)
    end
  end

  def self.down
    EnabledModule.delete_all("name = 'calendar' OR name = 'gantt'")
  end
end
