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

module TableHelpers
  module ColumnType
    # Column to specify start date and due date using an ascii calendar.
    #
    # The title of the column is "MTWTFSS" to represent the days of the week.
    #
    # The Monday is the next occuring Monday meaning the dates can be different
    # from one test run to another. To always use the same dates please use
    # `travel_to` with a fixed date.
    #
    # Use 'X' to mark the days from start to due date. Only the first and last
    # 'X' are considered as start and due dates.
    # Use '[' to mark the start date only and ']' for the due date only.
    # Any other character is ignored
    #
    # Example:
    #
    #   | subject                   | MTWTFSS   |
    #   | main                      | XXX       |
    #   | crossing non working days |  XXXX..XX |
    #   | start date only           | [         |
    #   | due date only             |     ]     |
    #   | no dates                  |           |
    #
    # Adapted from (now deleted) original implementation
    # in `spec/support/schedule_helpers/chart_builder.rb`.
    class Schedule < Generic
      def attributes_for_work_package(_attribute, work_package)
        {
          start_date: work_package.start_date,
          due_date: work_package.due_date,
          ignore_non_working_days: work_package.ignore_non_working_days
        }
      end

      def extract_data(_attribute, raw_header, work_package_data, _work_packages_data)
        raw_value = work_package_data.dig(:row, raw_header)

        {
          attributes: scheduling_attributes(raw_header, raw_value),
          **metadata_for_raw_value(raw_value)
        }
      end

      private

      def scheduling_attributes(reference, timespan)
        nb_days_from_origin_monday = reference.index("M")

        start_pos = timespan.index("[") || timespan.index("X")
        due_pos = timespan.rindex("]") || timespan.rindex("X")
        {
          start_date: start_pos && (current_monday - nb_days_from_origin_monday + start_pos),
          due_date: due_pos && (current_monday - nb_days_from_origin_monday + due_pos)
        }
      end

      def current_monday
        Date.current.next_occurring(:monday)
      end
    end
  end
end
