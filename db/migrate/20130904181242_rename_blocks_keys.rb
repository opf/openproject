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

class RenameBlocksKeys < ActiveRecord::Migration
  REPLACED = {
    "issuesassignedtome" => "issues_assigned_to_me",
    "issuesreportedbyme" => "issues_reported_by_me",
    "issuetracking" => "issue_tracking",
    "issueswatched" => "issues_watched",
    "news" => "news_latest",
    "timelog" => "spent_time",
    "projectdetails" => "project_details",
    "projectdescription" => "project_description"
  }

  def self.up
    migrate(REPLACED)
  end

  def self.down
    migrate(REPLACED.invert)
  end

  def self.migrate(replacer)
    MyProjectsOverview.all.each do |my_project_overview|
      ['top', 'left', 'right', 'hidden'].each do |attribute|
        old = my_project_overview.send(attribute)
        my_project_overview.send(attribute+'=',replace(old,replacer))
      end
      my_project_overview.save!
    end
  end

  def self.replace(array, replacer)
    array.map { |element| replacer[element] ? replacer[element] : element }
  end
end
