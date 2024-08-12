#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Backlogs
  class QueryBacklogsSelect < Queries::WorkPackages::Selects::WorkPackageSelect
    class_attribute :backlogs_selects

    self.backlogs_selects = {
      story_points: {
        sortable: "#{WorkPackage.table_name}.story_points",
        summable: true
      },
      position: {
        default_order: "asc",
        # Sort by position only, always show work_packages without a position at the end
        sortable: "CASE WHEN #{WorkPackage.table_name}.position IS NULL THEN 1 ELSE 0 END ASC, #{WorkPackage.table_name}.position"
      }
    }

    def self.instances(context = nil)
      return [] if context && !context.backlogs_enabled?

      backlogs_selects.map do |name, options|
        new(name, options)
      end
    end
  end
end
