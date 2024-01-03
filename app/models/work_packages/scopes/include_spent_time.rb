#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackages::Scopes::IncludeSpentTime
  extend ActiveSupport::Concern

  class_methods do
    def include_spent_time(user, work_package = nil)
      query = join_time_entries(user)

      scope = left_join_self_and_descendants(user, work_package)
              .joins(query.join_sources)
              .group(:id)
              .select('SUM(time_entries.hours) AS hours')

      if work_package
        scope.where(id: work_package.id)
      else
        scope
      end
    end

    protected

    def join_time_entries(user)
      join_condition = time_entries_table[:work_package_id]
                       .eq(wp_descendants[:id])
                       .and(allowed_to_view_time_entries(user))

      wp_table
        .outer_join(time_entries_table)
        .on(join_condition)
    end

    def allowed_to_view_time_entries(user)
      time_entries_table[:id].in(TimeEntry.not_ongoing.visible(user).select(:id).arel)
    end

    def wp_table
      @wp_table ||= arel_table
    end

    def wp_descendants
      # Relies on a table called descendants to exist in the scope
      # which is provided by left_join_self_and_descendants
      @wp_descendants ||= wp_table.alias('descendants')
    end

    def time_entries_table
      @time_entries_table ||= TimeEntry.arel_table
    end
  end
end
