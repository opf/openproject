class AddBoardsPermissions < ActiveRecord::Migration
  def self.up
    Permission.create :controller => "boards", :action => "new", :description => "button_add", :sort => 2000, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "boards", :action => "edit", :description => "button_edit", :sort => 2005, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "boards", :action => "destroy", :description => "button_delete", :sort => 2010, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action("boards", "new").destroy
    Permission.find_by_controller_and_action("boards", "edit").destroy
    Permission.find_by_controller_and_action("boards", "destroy").destroy
  end
end
