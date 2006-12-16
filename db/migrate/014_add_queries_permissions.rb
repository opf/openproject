class AddQueriesPermissions < ActiveRecord::Migration
  def self.up
    Permission.create :controller => "projects", :action => "add_query", :description => "button_create", :sort => 600, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'add_query']).destroy
  end
end
