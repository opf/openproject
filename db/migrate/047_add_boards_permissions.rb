#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddBoardsPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

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
