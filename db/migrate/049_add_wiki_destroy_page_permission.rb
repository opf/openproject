class AddWikiDestroyPagePermission < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => 'wiki', :action => 'destroy', :description => 'button_delete', :sort => 1740, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action('wiki', 'destroy').destroy
  end
end
