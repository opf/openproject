class CalendarAndActivity < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "projects", :action => "activity", :description => "label_activity", :sort => 160, :is_public => true, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "projects", :action => "calendar", :description => "label_calendar", :sort => 165, :is_public => true, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "projects", :action => "gantt", :description => "label_gantt", :sort => 166, :is_public => true, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'activity']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'calendar']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'gantt']).destroy
  end
end
