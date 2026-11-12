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

module Project::Phases::Scopes::CoveringDatesOrDaysOfWeek
  extend ActiveSupport::Concern
  using CoreExtensions::SquishSql

  class_methods do
    # Fetches all phases that cover specific days of the week, and/or specific dates.
    #
    # The period considered is from the phase start date to the due date.
    #
    # @param dates Date[] An array of the Date objects.
    # @param days_of_week number[] An array of the ISO days of the week to
    #   consider. 1 is Monday, 7 is Sunday.
    def covering_dates_or_days_of_week(days_of_week: [], dates: [])
      days_of_week = Array(days_of_week)
      dates = Array(dates)
      return none if days_of_week.empty? && dates.empty?

      ids_sql = sanitize_sql([<<~SQL.squish, { days_of_week:, dates: }])
        WITH
          -- select phases with at least one date
          phases_with_dates AS (
            SELECT
              id,
              COALESCE(start_date, finish_date) AS start_date,
              COALESCE(finish_date, start_date) AS finish_date
            FROM project_phases
            WHERE
              start_date IS NOT NULL
              OR finish_date IS NOT NULL
          )

        SELECT
          id
        FROM
          phases_with_dates
        WHERE
          -- Check if the range covers any of the provided days of week. It is
          -- done by comparing number of days from start_date to first target
          -- day of week with number of days in range. If number is less or
          -- eqal, then the range covers the target day of week
          EXISTS (
            SELECT 1
            FROM UNNEST(ARRAY[:days_of_week]::INT[]) AS target_dow
            WHERE (target_dow + 7 - EXTRACT(ISODOW FROM start_date)::INT) % 7 <= finish_date - start_date
          )
          OR
          -- Check if the range covers any of the provided dates
          EXISTS (
            SELECT 1
            FROM UNNEST(ARRAY[:dates]::DATE[]) AS target_date
            WHERE target_date BETWEEN start_date AND finish_date
          )
      SQL

      where("id IN (#{ids_sql})")
    end
  end
end
