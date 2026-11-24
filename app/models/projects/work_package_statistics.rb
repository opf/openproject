# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::WorkPackageStatistics
  ATTRIBUTES = %i[
    work_packages_total
    work_packages_open
    work_packages_closed
    work_packages_overdue
    work_packages_completion
  ].freeze

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Adds one column per entry of ATTRIBUTES to every loaded project.
    # Only work packages visible to the user are counted, so the numbers never
    # reveal work packages the user is not allowed to see.
    def with_work_package_statistics(user = User.current)
      scope = all
      scope = scope.select("projects.*") if scope.select_values.empty?

      scope
        .select(ATTRIBUTES.map { |attribute| "COALESCE(wp_stats.#{attribute}, 0) AS #{attribute}" })
        .joins("LEFT JOIN (#{work_package_statistics_sql(user)}) wp_stats ON projects.id = wp_stats.project_id")
    end

    def work_package_statistics_sql(user = User.current)
      WorkPackage
        .visible(user)
        .joins(:status)
        .group(:project_id)
        .select(:project_id, *work_package_statistics_aggregates(user))
        .to_sql
    end

    private

    def work_package_statistics_aggregates(user)
      closed_category = connection.quote(Status.categories[:closed])
      closed = "statuses.category = #{closed_category}"
      open = "statuses.category IS DISTINCT FROM #{closed_category}"
      overdue = sanitize_sql_array(["#{open} AND work_packages.due_date < ?", user.today])

      [
        "COUNT(*) AS work_packages_total",
        "COUNT(*) FILTER (WHERE #{open}) AS work_packages_open",
        "COUNT(*) FILTER (WHERE #{closed}) AS work_packages_closed",
        "COUNT(*) FILTER (WHERE #{overdue}) AS work_packages_overdue",
        "ROUND(COUNT(*) FILTER (WHERE #{closed}) * 100.0 / COUNT(*))::integer AS work_packages_completion"
      ]
    end
  end
end
