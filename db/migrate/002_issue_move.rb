#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class IssueMove < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "projects", :action => "move_issues", :description => "button_move", :sort => 1061, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'projects', 'move_issues']).destroy
  end
end
