#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
