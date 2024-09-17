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

module WorkPackages::Scopes::IncludeSpentTime
  extend ActiveSupport::Concern

  class_methods do
    def include_spent_time(user, work_package = nil)
      scope = left_join_self_and_descendants(user, work_package)
              .with(visible_time_entries_cte.name => allowed_to_view_time_entries(user))
              .joins(join_visible_time_entries.join_sources)
              .group(:id)
              .select("SUM(#{visible_time_entries_cte.name}.hours) AS hours")

      if work_package
        scope.where(id: work_package.id)
      else
        scope
      end
    end

    protected

    def join_visible_time_entries
      wp_table
        .outer_join(visible_time_entries_cte)
        .on(visible_time_entries_cte[:work_package_id].eq(wp_descendants[:id]))
    end

    def allowed_to_view_time_entries(user)
      TimeEntry.not_ongoing.visible(user).select(:id, :work_package_id, :hours).arel
    end

    def wp_table
      @wp_table ||= arel_table
    end

    def wp_descendants
      # Relies on a table called descendants to exist in the scope
      # which is provided by left_join_self_and_descendants
      @wp_descendants ||= wp_table.alias("descendants")
    end

    def visible_time_entries_cte
      @visible_time_entries_cte ||= Arel::Table.new("visible_time_entries")
    end
  end
end
