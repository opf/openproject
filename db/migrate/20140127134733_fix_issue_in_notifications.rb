#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class FixIssueInNotifications < ActiveRecord::Migration
  def up
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("issue_added","work_package_added")}
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("issue_updated","work_package_updated")}
  end

  def down
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("work_package_added","issue_added")}
    Setting['notified_events']= Setting['notified_events'].map {|m| m.gsub("work_package_updated","issue_updated")}
  end
end
