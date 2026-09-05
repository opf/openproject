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

module OpenProject::Backlogs::CreatedResolved
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
      :workpackages if @collect[:workpackages].include? name
    end

    def collect_data
      initialize_self_for_collection
      data_for_dates.each do |day_data| 
        date = day_data["date"]
        date = Date.parse(date) unless date.is_a?(Date)
       
        day_data.each do |key, value|
          next if key == "date"

          self.transform_values do |v|
            self[key][date] = value.to_f
          end
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
          COUNT(*) FILTER (WHERE date_trunc('day', work_packages.created_at) = days.date) AS wp_created,
          COUNT(*) FILTER (
              WHERE work_package_journals.status_id IN (#{project.done_statuses.pluck(:id).join(', ')}) AND
              (days.DATE::TIMESTAMP + interval '23:59:59') AT TIME ZONE 'Etc/UTC' = (date_trunc('day', journals.created_at::TIMESTAMP)+ interval '23:59:59') AT TIME ZONE 'Etc/UTC'
            ) AS wp_resolved
        FROM
          work_package_journals
        LEFT JOIN
          journals
        ON work_package_journals.id = journals.data_id
          AND journals.data_type = '#{Journal::WorkPackageJournal.name}'
          AND #{container_query}
          AND #{project_id_query}
        LEFT JOIN 
          work_packages 
        ON journals.journable_id = work_packages.id
        JOIN
          (#{day_query.to_sql}) days
        ON (days.date::timestamp + interval '23:59:59') AT TIME ZONE '#{User.current.time_zone.tzinfo.name}' <@ journals.validity_period
        GROUP BY days.date
        ORDER BY days.date
      SQL

      Journal::WorkPackageJournal.connection.select_all query_string
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
