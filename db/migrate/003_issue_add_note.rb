class IssueAddNote < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "issues", :action => "add_note", :description => "label_add_note", :sort => 1057, :mail_option => 1, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'issues', 'add_note']).destroy
  end
end
