#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module WorkPackages::Scopes::CoveringDaysOfWeek
  extend ActiveSupport::Concern
  using CoreExtensions::SquishSql

  class_methods do
    # Fetches all work packages that cover specific days of the week.
    #
    # The period considered is from the work package start date to the due date.
    #
    # @param days_of_week number[] An array of the ISO days of the week to
    #   consider. 1 is Monday, 7 is Sunday.
    def covering_days_of_week(days_of_week)
      days_of_week = Array(days_of_week)
      return none if days_of_week.empty?

      where("id IN (#{query(days_of_week)})")
    end

    private

    def query(days_of_week)
      sql = <<~SQL.squish
        -- select work packages dates with their followers dates
        WITH work_packages_with_dates AS (
          SELECT work_packages.id,
            work_packages.start_date AS work_package_start_date,
            work_packages.due_date AS work_package_due_date
          FROM work_packages
          WHERE work_packages.ignore_non_working_days = false
            AND (
              work_packages.start_date IS NOT NULL
              OR work_packages.due_date IS NOT NULL
            )
          ORDER BY work_packages.id
        ),
        -- coalesce non-existing dates of work package to get period start/end
        work_packages_periods AS (
          SELECT id,
            LEAST(work_package_start_date, work_package_due_date) AS start_date,
            GREATEST(work_package_start_date, work_package_due_date) AS end_date
          FROM work_packages_with_dates
        ),
        -- expand period into days of the week. Limit to 7 days (more would be useless).
        work_packages_days_of_week AS (
          SELECT id,
            extract(
              isodow
              from generate_series(
                  work_packages_periods.start_date,
                  LEAST(
                    work_packages_periods.start_date + 6,
                    work_packages_periods.end_date
                  ),
                  '1 day'
                )
            ) AS dow
            FROM work_packages_periods
        )
        -- select id of work packages covering the given days
        SELECT DISTINCT id
        FROM work_packages_days_of_week
        WHERE dow IN (:days_of_week)
      SQL

      sanitize_sql([sql, { days_of_week: }])
    end
  end
end
