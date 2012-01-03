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
