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

require Rails.root.join("db","migrate","migration_utils","utils").to_s

class LegacyIssuesBacklogsDataToWorkPackages < ActiveRecord::Migration

  def up
    if legacy_backlog_data_exists?
      execute <<-SQL
        UPDATE work_packages AS W
        SET position = (SELECT L.position FROM legacy_issues AS L WHERE L.id = W.id),
            story_points = (SELECT L.story_points FROM legacy_issues AS L WHERE L.id = W.id),
            remaining_hours = (SELECT L.remaining_hours FROM legacy_issues AS L WHERE L.id = W.id)
      SQL
    end
  end

  def down
    if legacy_backlog_data_exists?
      execute <<-SQL
        UPDATE legacy_issues AS L
        SET position = (SELECT W.position FROM work_packages AS W WHERE W.id = L.id),
            story_points = (SELECT W.story_points FROM work_packages AS W WHERE W.id = L.id),
            remaining_hours = (SELECT W.remaining_hours FROM work_packages AS W WHERE W.id = L.id)
      SQL
    end
  end

  private

  class LegacyIssue < ActiveRecord::Base
  end

  def legacy_backlog_data_exists?
    LegacyIssue.column_names & ['position', 'story_points', 'remaining_hours'] == 3
  end
end
