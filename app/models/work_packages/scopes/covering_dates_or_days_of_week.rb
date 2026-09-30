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

module WorkPackages::Scopes::CoveringDatesOrDaysOfWeek
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
    def covering_dates_or_days_of_week(days_of_week: [], dates: [])
      work_packages_periods_cte = work_packages_periods_cte_for_covering_work_packages
      where_covers_periods(work_packages_periods_cte, days_of_week, dates)
    end

    def predecessors_needing_relations_rescheduling(days_of_week: [], dates: [])
      work_packages_periods_cte = work_packages_periods_cte_for_predecessors_needing_relations_rescheduling
      where_covers_periods(work_packages_periods_cte, days_of_week, dates)
    end

    private

    def where_covers_periods(work_packages_periods_cte, days_of_week, dates)
      days_of_week = Array(days_of_week)
      dates = Array(dates)
      return none if days_of_week.empty? && dates.empty?

      covering_work_packages_query_sql = <<~SQL.squish
        -- select work packages dates
        WITH
          -- cte returning a table with work package id, period start_date and end_date
          #{work_packages_periods_cte}

        -- select id of work packages covering the given days
        SELECT id
        FROM work_packages_periods
        WHERE
          -- Check if the range covers any of the provided days of week. It is
          -- done by comparing number of days from start_date to first target
          -- day of week with number of days in range. If number is less or
          -- eqal, then the range covers the target day of week
          EXISTS (
            SELECT 1
            FROM UNNEST(ARRAY[:days_of_week]::INT[]) AS target_dow
            WHERE (target_dow + 7 - EXTRACT(ISODOW FROM start_date)::INT) % 7 <= (end_date - start_date)
          )
          OR
          -- Check if the range covers any of the provided dates
          EXISTS (
            SELECT 1
            FROM unnest(Array[:dates]::DATE[]) AS target_date
            WHERE target_date BETWEEN start_date AND end_date
          )
      SQL

      covering_work_packages_query_sql = sanitize_sql([covering_work_packages_query_sql, { days_of_week:, dates: }])

      where("id IN (#{covering_work_packages_query_sql})")
    end

    def work_packages_periods_cte_for_covering_work_packages
      <<~SQL.squish
        -- select work packages dates
        work_packages_with_dates AS (
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
        )
      SQL
    end

    def work_packages_periods_cte_for_predecessors_needing_relations_rescheduling
      <<~SQL.squish
        follows_relations
          AS (SELECT
            relations.id as id,
            relations.to_id as pred_id,
            relations.from_id as succ_id,
            COALESCE(wp_pred.due_date, wp_pred.start_date) + INTERVAL '1 DAY' as pred_date,
            COALESCE(wp_succ.start_date, wp_succ.due_date) - INTERVAL '1 DAY' as succ_date,
            wp_succ.schedule_manually as succ_schedule_manually
          FROM relations
          LEFT JOIN work_packages wp_pred ON relations.to_id = wp_pred.id
          LEFT JOIN work_packages wp_succ ON relations.from_id = wp_succ.id
          WHERE relation_type = 'follows'
        ),
        -- select automatic follows relations. A relation is automatic if the
        -- successor is scheduled automatically and both successor and
        -- predecessor have dates
        -- also excluded relations that have no duration (predecessor and successor "touch" each other)
        automatic_follows_relations AS (
          SELECT *
          FROM follows_relations
          WHERE succ_schedule_manually = false
            AND pred_date IS NOT NULL
            AND succ_date IS NOT NULL
            AND pred_date <= succ_date
        ),
        -- keep only the longest relation for each successor
        -- get the predecessor id and the relation period for each relation
        work_packages_periods AS (
          SELECT DISTINCT ON (succ_id)
            pred_id as id,
            pred_date::DATE as start_date,
            succ_date::DATE as end_date
          FROM automatic_follows_relations
          ORDER BY succ_id, pred_date ASC
        )
      SQL
    end
  end
end
