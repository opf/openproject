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

module ScheduleHelpers
  class ChartRepresenter
    LINE = "%<id>s | %<days>s |".freeze

    def self.normalized_to_s(reference_chart, other_chart)
      order = reference_chart.work_package_names
      id_column_size = [reference_chart, other_chart].map(&:id_column_size).max
      first_day = [reference_chart, other_chart].map(&:first_day).min
      last_day = [reference_chart, other_chart].map(&:last_day).max
      [reference_chart, other_chart]
        .map { |chart| chart.with(order:, id_column_size:, first_day:, last_day:) }
        .map(&:to_s)
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
