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
  class GanttBuilderDays < GanttBuilder
    def build_column_dates_range(range)
      range.to_a
    end

    def header_row_parts
      %i[years months days]
    end

    def work_packages_on_date(date, work_packages)
      work_packages.select { |work_package| wp_on_day?(work_package, date) }
    end

    def calc_start_offset(_work_package, _date)
      0.0
    end

    def calc_end_offset(_work_package, _date)
      0.0
    end

    def milestone_position_centered?
      true
    end

    def wp_on_day?(work_package, date)
      start_date, end_date = wp_dates(work_package)
      (start_date..end_date).cover?(date)
    end
  end
end
