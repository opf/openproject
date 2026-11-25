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

module WorkPackages
  # Personal productivity figures for the work packages assigned to a user.
  #
  # Work packages have no "closed at" column, so the moment a work package was
  # completed is taken from its journals: the latest journal version that moved
  # it from a non-closed status into a closed one.
  class ProductivityReport
    WEEKS_OF_HISTORY = 8
    LIST_LIMIT = 10
    RECENTLY_COMPLETED_DAYS = 7

    WeeklyProgress = Data.define(:week_start, :completed)
    ProjectBreakdown = Data.define(:project, :total, :open, :closed, :overdue) do
      def completion
        total.zero? ? 0 : (closed * 100.0 / total).round
      end
    end

    attr_reader :user, :today

    def initialize(user:, today: user.today)
      @user = user
      @today = today
    end

    def assigned
      WorkPackage.visible(user).where(assigned_to: user)
    end

    def open_work_packages
      assigned.with_status_open
    end

    def closed_work_packages
      assigned.with_status_closed
    end

    def overdue_work_packages
      open_work_packages.where(due_date: ...today)
    end

    def due_this_week
      open_work_packages.where(due_date: today..current_week.last)
    end

    def due_work_packages
      open_work_packages
        .where.not(due_date: nil)
        .where(due_date: ..current_week.last)
        .includes(:project, :status, :type)
        .order(:due_date, :id)
        .limit(LIST_LIMIT)
    end

    def recently_completed
      closed_with_closing_date
        .where(closings: { closed_at: (today - RECENTLY_COMPLETED_DAYS).in_time_zone(user.time_zone).. })
        .includes(:project, :status, :type)
        .order("closings.closed_at DESC")
        .limit(LIST_LIMIT)
    end

    def completed_this_week_count
      weekly_progress.last.completed
    end

    def completion_rate
      percentage(closed_work_packages.count, assigned.count)
    end

    def on_time_rate
      with_due_date = closed_with_closing_date.where.not(due_date: nil).to_a
      on_time = with_due_date.count { |work_package| closing_date(work_package) <= work_package.due_date }

      percentage(on_time, with_due_date.size)
    end

    def weekly_progress
      @weekly_progress ||= begin
        first_week = current_week.first - (WEEKS_OF_HISTORY - 1).weeks
        counts = completion_dates_since(first_week)
                   .map { |date| date.beginning_of_week(beginning_of_week) }
                   .tally

        Array.new(WEEKS_OF_HISTORY) do |index|
          week_start = first_week + index.weeks
          WeeklyProgress.new(week_start:, completed: counts.fetch(week_start, 0))
        end
      end
    end

    def project_breakdown
      counts = breakdown_counts
      projects = Project.where(id: counts.map(&:first)).index_by(&:id)

      counts
        .map { |project_id, *numbers| ProjectBreakdown.new(projects[project_id], *numbers) }
        .sort_by { |row| [-row.open, row.project.name] }
    end

    private

    def breakdown_counts
      assigned
        .joins(:status)
        .group(:project_id)
        .pluck(:project_id, *breakdown_aggregates)
    end

    def current_week
      @current_week ||= today.all_week(beginning_of_week)
    end

    def beginning_of_week
      OpenProject::Internationalization::Date.beginning_of_week
    end

    def percentage(part, total)
      return 0 if total.zero?

      (part * 100.0 / total).round
    end

    def closed_with_closing_date
      closed_work_packages
        .joins("JOIN (#{closings_sql}) closings ON closings.work_package_id = work_packages.id")
        .select("work_packages.*, closings.closed_at")
    end

    def closing_date(work_package)
      work_package.closed_at.in_time_zone(user.time_zone).to_date
    end

    def completion_dates_since(date)
      closed_with_closing_date
        .where(closings: { closed_at: date.in_time_zone(user.time_zone).. })
        .map { |work_package| closing_date(work_package) }
    end

    def closings_sql
      <<~SQL.squish
        SELECT transitions.journable_id AS work_package_id, MAX(transitions.created_at) AS closed_at
        FROM (#{status_transitions_sql}) transitions
        JOIN #{Status.table_name} new_status ON new_status.id = transitions.status_id
        LEFT JOIN #{Status.table_name} previous_status ON previous_status.id = transitions.previous_status_id
        WHERE new_status.category = #{closed_category}
          AND previous_status.category IS DISTINCT FROM #{closed_category}
        GROUP BY transitions.journable_id
      SQL
    end

    # One row per journal version with the status before and after that version.
    def status_transitions_sql
      <<~SQL.squish
        SELECT journals.journable_id,
               journals.created_at,
               work_package_journals.status_id,
               LAG(work_package_journals.status_id) OVER (
                 PARTITION BY journals.journable_id ORDER BY journals.version
               ) AS previous_status_id
        FROM #{Journal.table_name} journals
        JOIN #{Journal::WorkPackageJournal.table_name} work_package_journals
          ON journals.data_type = #{quote(Journal::WorkPackageJournal.name)}
         AND journals.data_id = work_package_journals.id
        WHERE journals.journable_type = #{quote(WorkPackage.name)}
          AND journals.journable_id IN (#{closed_work_packages.select(:id).to_sql})
      SQL
    end

    def breakdown_aggregates
      closed = "statuses.category = #{closed_category}"
      open = "statuses.category IS DISTINCT FROM #{closed_category}"
      overdue = WorkPackage.sanitize_sql_array(["#{open} AND work_packages.due_date < ?", today])

      [
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE #{open})"),
        Arel.sql("COUNT(*) FILTER (WHERE #{closed})"),
        Arel.sql("COUNT(*) FILTER (WHERE #{overdue})")
      ]
    end

    def closed_category
      quote(Status.categories[:closed])
    end

    def quote(value)
      WorkPackage.connection.quote(value)
    end
  end
end
