class IssueMove < ActiveRecord::Migration
  def self.up
    Permission.create :controller => "projects", :action => "move_issues", :description => "button_move", :sort => 1061, :mail_option => 1, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'move_issues']).destroy
  end
end
