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

module WorkPackages::Scopes::CoveringDatesAndDaysOfWeek
  extend ActiveSupport::Concern
  using CoreExtensions::SquishSql

  class_methods do
    # Fetches all work packages that cover specific days of the week, and/or specific dates.
    #
    # The period considered is from the work package start date to the due date.
    #
    # @param dates Date[] An array of the Date objects.
    # @param days_of_week number[] An array of the ISO days of the week to
    #   consider. 1 is Monday, 7 is Sunday.
    def covering_dates_and_days_of_week(days_of_week: [], dates: [])
      days_of_week = Array(days_of_week)
      dates = Array(dates)
      return none if days_of_week.empty? && dates.empty?

      where("id IN (#{query(days_of_week, dates)})")
    end

    private

    def query(days_of_week, dates)
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
        ),
        -- coalesce non-existing dates of work package to get period start/end
        work_packages_periods AS (
          SELECT id,
            LEAST(work_package_start_date, work_package_due_date) AS start_date,
            GREATEST(work_package_start_date, work_package_due_date) AS end_date
          FROM work_packages_with_dates
        ),
        -- All days between the start date of a work package and its due date
        covered_dates AS (
          SELECT
           id,
           generate_series(work_packages_periods.start_date,
                           work_packages_periods.end_date,
                           '1 day')          AS date
          FROM work_packages_periods
        ),
        -- All days between the start date of a work package and its due date including the day of the week for each date
        covered_dates_and_wday AS (
          SELECT
            id,
            date,
            EXTRACT(isodow FROM date) dow
          FROM covered_dates
        )
        -- select id of work packages covering the given days
        SELECT id FROM covered_dates_and_wday
        WHERE dow IN (:days_of_week) OR date IN (:dates)
      SQL

      sanitize_sql([sql, { days_of_week:, dates: }])
    end
  end
end
