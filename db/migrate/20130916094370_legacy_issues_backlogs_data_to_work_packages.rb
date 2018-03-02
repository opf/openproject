#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require Rails.root.join('db', 'migrate', 'migration_utils', 'utils').to_s

class LegacyIssuesBacklogsDataToWorkPackages < ActiveRecord::Migration[5.0]
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
    backlogs_columns = ['position', 'story_points', 'remaining_hours']

    ActiveRecord::Base.connection.table_exists?('legacy_issues') && (LegacyIssue.column_names & backlogs_columns).sort == backlogs_columns.sort
  end
end
