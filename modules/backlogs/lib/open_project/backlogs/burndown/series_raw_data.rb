#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::Burndown
  class SeriesRawData < Hash
    def initialize(*args)
      @collect = args.pop
      @sprint = args.pop
      @project = args.pop
      super(*args)
    end

    attr_reader :collect
    attr_reader :sprint
    attr_reader :project

    def collect_names
      @names ||= @collect.to_a.map(&:last).flatten
    end

    def unit_for(name)
      return :points if @collect[:points].include? name
    end

    def collect_data
      initialize_self_for_collection

      data_for_dates(collected_days).each do |day_data|
        date = day_data['date']
        date = date.is_a?(Date) ? date : Date.parse(date)

        day_data.each do |key, value|
          next if key == 'date'

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
      ON work_package_journals.journal_id = id_journals.id
        AND #{fixed_version_query}
        AND #{project_id_query}
        AND #{type_id_query}
        AND #{status_query}
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
      raise 'dates must not be empty!' if dates.empty?

      query = <<-SQL
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
              ON journals.id = work_package_journals.journal_id
                AND #{fixed_version_query}
                AND #{project_id_query}
                AND #{type_id_query}
                AND #{status_query})
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

      query
    end

    def dates_of_interest_join_table(dates)
      raise 'dates must not be empty!' if dates.empty?

      @date_join ||= dates.map { |date|
        "SELECT CAST('#{date}' AS DATE) AS date"
      }.join(' UNION ')
    end

    def status_query
      @status_query ||= begin
        non_closed_statuses = Status.where(is_closed: false).select(:id).map(&:id)

        done_statuses_for_project = project.done_statuses.select(:id).map(&:id)

        open_status_ids = non_closed_statuses - done_statuses_for_project

        "(#{Journal::WorkPackageJournal.table_name}.status_id IN (#{open_status_ids.join(',')}))"
      end
    end

    def fixed_version_query
      @fixed_version_query ||= "(#{Journal::WorkPackageJournal.table_name}.fixed_version_id = #{sprint.id})"
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
      key == 'remaining_hours' && story_has_children?(story)
    end

    def collected_types
      @collected_types ||= Story.types << Task.type
    end
  end
end
