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

class EnableCalendarAndGanttModulesWhereAppropriate < ActiveRecord::Migration
  def self.up
    EnabledModule.find(:all, :conditions => ["name = ?", 'issue_tracking']).each do |e|
      EnabledModule.create(:name => 'calendar', :project_id => e.project_id)
      EnabledModule.create(:name => 'gantt', :project_id => e.project_id)
    end
  end

  def self.down
    EnabledModule.delete_all("name = 'calendar' OR name = 'gantt'")
  end
end
