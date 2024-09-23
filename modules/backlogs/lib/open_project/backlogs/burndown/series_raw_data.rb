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
      @names ||= @collect.to_a.map(&:last).flatten
    end

    def unit_for(name)
      :points if @collect[:points].include? name
    end

    def collect_data
      initialize_self_for_collection

      data_for_dates(collected_days).each do |day_data|
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
      @collected_days ||= begin
        days = sprint.days(nil)
        days.sort.select { |d| d <= Date.today }
      end
    end

    def data_for_dates(dates)
      return [] if dates.empty?

      query_string = <<-SQL
      SELECT
        date_journals.date,
        SUM(work_package_journals.story_points) as story_points
      FROM
        work_package_journals
      JOIN journals AS id_journals
      ON work_package_journals.id = id_journals.data_id
        AND id_journals.data_type = '#{Journal::WorkPackageJournal.name}'
        AND #{version_query}
        AND #{project_id_query}
        AND #{type_id_query}
        #{and_status_query}
      JOIN
        (
          #{authoritative_journal_for_date(dates)}
        ) AS date_journals
      ON date_journals.journable_id = id_journals.journable_id
        AND date_journals.version = id_journals.version
        AND id_journals.journable_type = 'WorkPackage'
      GROUP BY date_journals.date
      ORDER BY date_journals.date
      SQL

      Journal::WorkPackageJournal.connection.select_all query_string
    end

    def authoritative_journal_for_date(dates)
      raise "dates must not be empty!" if dates.empty?

      <<-SQL
      SELECT
        d.date,
        j.journable_id,
        MAX(j.version) as version
      FROM
        (
          #{dates_of_interest_join_table(dates)}
        ) as d
      JOIN
        (
          SELECT
            CAST(j.created_at AS DATE) AS created_at,
            j.journable_id,
            MAX(j.version) as version
          FROM
            journals AS j
          WHERE
            j.journable_id IN (
              SELECT journable_id
              FROM
                journals
              JOIN
                work_package_journals
              ON work_package_journals.id = journals.data_id
                AND journals.data_type = '#{Journal::WorkPackageJournal.name}'
                AND #{version_query}
                AND #{project_id_query}
                AND #{type_id_query}
                #{and_status_query})
          GROUP BY
            CAST(j.created_at AS DATE),
            j.journable_type,
            j.journable_id
          HAVING j.journable_type = 'WorkPackage'
          ORDER BY j.journable_id, version
        ) as j
      ON d.date >= j.created_at
      GROUP BY d.date, j.journable_id
      ORDER BY j.journable_id, d.date, version
      SQL
    end

    def dates_of_interest_join_table(dates)
      raise "dates must not be empty!" if dates.empty?

      @date_join ||= dates.map do |date|
        "SELECT CAST('#{date}' AS DATE) AS date"
      end.join(" UNION ")
    end

    def and_status_query
      @status_query ||= begin
        non_closed_statuses = Status.where(is_closed: false).select(:id).map(&:id)

        done_statuses_for_project = project.done_statuses.select(:id).map(&:id)

        open_status_ids = non_closed_statuses - done_statuses_for_project

        if open_status_ids.empty?
          ""
        else
          "AND (#{Journal::WorkPackageJournal.table_name}.status_id IN (#{open_status_ids.join(',')}))"
        end
      end
    end

    def version_query
      @version_query ||= "(#{Journal::WorkPackageJournal.table_name}.version_id = #{sprint.id})"
    end

    def project_id_query
      @project_id_query ||= "(#{Journal::WorkPackageJournal.table_name}.project_id = #{project.id})"
    end

    def type_id_query
      @type_id_query ||= "(#{Journal::WorkPackageJournal.table_name}.type_id in (#{collected_types.join(',')}))"
    end

    def ignore_if_has_parent
      @ignore_if_has_parent ||= "(#{Journal::WorkPackageJournal.table_name}.parent_id IS NOT NULL)"
    end

    def collected_from_children?(key, story)
      key == "remaining_hours" && story_has_children?(story)
    end

    def collected_types
      @collected_types ||= Story.types << Task.type
    end
  end
end
