class AddSearchPermission < ActiveRecord::Migration
  def self.up
    Permission.create :controller => "projects", :action => "search", :description => "label_search", :sort => 130, :is_public => true, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action('projects', 'roadmap').destroy
  end
end
