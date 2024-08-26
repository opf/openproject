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

module WorkPackage::PDFExport::Gantt
  class GanttBuilderMonths < GanttBuilder
    def build_column_dates_range(range)
      range
        .map { |d| Date.new(d.year, d.month, -1) }
        .uniq
    end

    def header_row_parts
      %i[years quarters months]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_month?(work_package, date) }
    end

    def calc_start_offset(work_package, date)
      test_date = Date.new(date.year, date.month, 1)
      start_date = work_package.start_date || work_package.due_date
      return 0 if start_date <= test_date

      width_per_day = @column_width.to_f / date.end_of_month.day
      day_in_month = start_date.day - 1
      day_in_month * width_per_day
    end

    def calc_end_offset(work_package, date)
      end_date = work_package.due_date || work_package.start_date
      test_date = Date.new(date.year, date.month, -1)
      return 0 if end_date >= test_date

      width_per_day = @column_width.to_f / test_date.day
      day_in_month = end_date.day
      @column_width - (day_in_month * width_per_day)
    end

    def wp_on_month?(work_package, date)
      start_date, end_date = wp_dates(work_package)
      (Date.new(start_date.year, start_date.month, 1)..Date.new(end_date.year, end_date.month, -1))
        .cover?(date)
    end
  end
end
