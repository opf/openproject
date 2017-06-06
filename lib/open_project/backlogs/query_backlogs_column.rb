#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Backlogs
  class QueryBacklogsColumn < Queries::WorkPackages::Columns::WorkPackageColumn
    class_attribute :backlogs_columns

    self.backlogs_columns = {
      story_points: {
        sortable: "#{WorkPackage.table_name}.story_points",
        summable: true
      },
      remaining_hours: {
        sortable: "#{WorkPackage.table_name}.remaining_hours",
        summable: true
      },
      position: {
        default_order: 'asc',
        # Sort by position only, always show work_packages without a position at the end
        sortable: "CASE WHEN #{WorkPackage.table_name}.position IS NULL THEN 1 ELSE 0 END ASC, #{WorkPackage.table_name}.position"
      }
    }

    def self.instances(context = nil)
      return [] if context && !context.backlogs_enabled?

      backlogs_columns.map do |name, options|
        new(name, options)
      end
    end
  end
end
