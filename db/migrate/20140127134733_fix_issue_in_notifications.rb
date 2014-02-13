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
  REPLACED = {
    "issue_added" => "work_package_added",
    "issue_updated" => "work_package_updated",
    "issue_priority_updated" => "work_package_priority_updated",
    "issue_note_added" => "work_package_note_added"
  }
  def up
    Setting['notified_events'] = replace(Setting['notified_events'], REPLACED)
  end

  def down
    Setting['notified_events'] = replace(Setting['notified_events'], REPLACED.invert)
  end
  
  private

  def replace(value,mapping)
    if value.respond_to? :map
      value.map { |s| mapping[s].nil? ? s : mapping[s] }
    else
      mapping[value].nil? ? value : mapping[value]
    end
  end
end
