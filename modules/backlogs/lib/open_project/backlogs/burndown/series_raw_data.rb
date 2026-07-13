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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Backlogs::Burndown
  class SeriesRawData < Hash
    def initialize(*args)
      @collect = args.pop
      @sprint = args.pop
      @project = args.pop
      super
    end

    attr_reader :collect, :sprint, :project

    def collect_names
      @collect_names ||= @collect.to_a.map(&:last).flatten
    end

    def unit_for(name)
      :points if @collect[:points].include? name
    end

    def collect_data
      initialize_self_for_collection

      data_for_dates.each do |day_data|
        date = day_data["date"]
        date = Date.parse(date) unless date.is_a?(Date)

        day_data.each do |key, value|
          next if key == "date"

          self[key][date] = value.to_f
        end
      end
    end

    private

    def initialize_self_for_collection
      date_hash = {}

      collected_days.each do |date|
        date_hash[date] = 0.0
      end

      collect_names.each do |c|
        self[c] = date_hash.dup
      end
    end

    def collected_days
      @collected_days ||= day_query.where(date: ..Time.zone.today).order(:date).map(&:date)
    end

    def data_for_dates
      query_string = <<~SQL.squish
        SELECT
          days.date,
          COALESCE(SUM(work_package_journals.story_points), 0.0) as story_points
        FROM
          work_package_journals
        LEFT JOIN
          journals
        ON work_package_journals.id = journals.data_id
          AND journals.data_type = '#{Journal::WorkPackageJournal.name}'
          AND #{container_query}
          AND #{project_id_query}
          #{and_status_query}
        JOIN
          (#{day_query.to_sql}) days
        ON (days.date::timestamp + interval '23:59:59') AT TIME ZONE '#{User.current.time_zone.tzinfo.name}' <@ journals.validity_period
        GROUP BY days.date
        ORDER BY days.date
      SQL

      Journal::WorkPackageJournal.connection.select_all query_string
    end

    def and_status_query
      non_closed_statuses = Status.where(is_closed: false).pluck(:id)

      done_statuses_for_project = project.done_statuses.pluck(:id)

      open_status_ids = non_closed_statuses - done_statuses_for_project

      if open_status_ids.empty?
        # No work packages count as remaining, so force the LEFT JOIN to
        # produce no matches, making the SUM evaluate to 0 (via COALESCE).
        "AND 1=0"
      else
        "AND (#{Journal::WorkPackageJournal.table_name}.status_id IN (#{open_status_ids.join(',')}))"
      end
    end

    def container_query
      "(#{Journal::WorkPackageJournal.table_name}.sprint_id = #{sprint.id})"
    end

    def project_id_query
      "(#{Journal::WorkPackageJournal.table_name}.project_id = #{project.id})"
    end

    def day_query
      lower_bound = sprint.start_date
      upper_date = sprint.finish_date
      upper_bound = Time.zone.today.clamp(lower_bound, upper_date)

      return Day.none unless upper_bound && lower_bound

      Day.working.from_range(from: lower_bound, to: upper_bound)
    end
  end
end
