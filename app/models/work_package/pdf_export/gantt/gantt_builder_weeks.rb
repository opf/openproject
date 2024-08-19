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
  class GanttBuilderWeeks < GanttBuilder
    def build_column_dates_range(range)
      range
        .map { |d| [d.cwyear, d.cweek] }
        .uniq
        .map { |year, week| Date.commercial(year, week, 1) }
    end

    def header_row_parts
      %i[years months weeks]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_week?(work_package, date) }
    end

    def calc_start_offset(work_package, date)
      start_date = work_package.start_date || work_package.due_date
      return 0 if start_date <= date.beginning_of_week

      width_per_day = @column_width.to_f / 7
      day_in_week = (start_date - date.beginning_of_week).to_i
      day_in_week * width_per_day
    end

    def calc_end_offset(work_package, date)
      end_date = work_package.due_date || work_package.start_date
      return 0 if end_date >= date.end_of_week

      width_per_day = @column_width.to_f / 7
      day_in_week = (end_date - date.beginning_of_week).to_i
      @column_width - (day_in_week * width_per_day)
    end

    def wp_on_week?(work_package, date)
      start_date, end_date = wp_dates(work_package)
      (start_date.beginning_of_week..end_date.end_of_week).cover?(date)
    end
  end
end
