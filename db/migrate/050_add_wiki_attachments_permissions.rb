class AddWikiAttachmentsPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => 'wiki', :action => 'add_attachment', :description => 'label_attachment_new', :sort => 1750, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => 'wiki', :action => 'destroy_attachment', :description => 'label_attachment_delete', :sort => 1755, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action('wiki', 'add_attachment').destroy
    Permission.find_by_controller_and_action('wiki', 'destroy_attachment').destroy
  end
end
