class AddRepositoriesChangesPermission < ActiveRecord::Migration
  def self.up
    Permission.create :controller => 'repositories', :action => 'changes', :description => 'label_change_plural', :sort => 1475, :is_public => true, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action('repositories', 'changes').destroy
  end
end
