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

module ScheduleHelpers
  class ChartRepresenter
    LINE = "%<id>s | %<days>s |".freeze

    def self.normalized_to_s(expected_chart, actual_chart)
      normalize_ignore_non_working_days_information(expected_chart, actual_chart)
      order = expected_chart.work_package_names
      id_column_size = [expected_chart, actual_chart].map(&:id_column_size).max
      first_day = [expected_chart, actual_chart].map(&:first_day).min
      last_day = [expected_chart, actual_chart].map(&:last_day).max
      [expected_chart, actual_chart]
        .map { |chart| chart.with(order:, id_column_size:, first_day:, last_day:) }
        .map(&:to_s)
    end

    # Define ignore_non_working_days attribute from +actual_chart+ when not
    # explicitly set in +expected_chart+.
    def self.normalize_ignore_non_working_days_information(expected_chart, actual_chart)
      expected_chart.work_packages_attributes.each do |work_package_attributes|
        next if work_package_attributes.has_key?(:ignore_non_working_days)

        name = work_package_attributes[:name]
        actual_attributes = actual_chart.work_package_attributes(name)
        next if actual_attributes.nil? || !actual_attributes.has_key?(:ignore_non_working_days)

        work_package_attributes[:ignore_non_working_days] = actual_attributes[:ignore_non_working_days]
      end
    end

    def initialize(id_column_size:, days_column_size:)
      @id_column_size = id_column_size
      @days_column_size = days_column_size
    end

    def add_row
      rows << []
    end

    def add_cell(text)
      rows.last << text
    end

    def rows
      @rows ||= []
    end

    def to_s
      line_template = "%<id>-#{@id_column_size}s | %<days>-#{@days_column_size}s |"
      rows.map do |row|
        line_template % { id: row[0], days: row[1] }
      end.join("\n")
    end
  end
end
