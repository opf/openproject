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
    # Column to specify how days are counted for duration.
    #
    # Can take values 'all days' or 'working days only' to set `ignore_non_working_days`
    # attribute to `true` or `false` respectively.
    #
    # Example:
    #
    #   | subject | days counting     |
    #   | wp 1    | all days          |
    #   | wp 2    | working days only |
    class DaysCounting < Generic
      def format(value)
        if value
          "all days"
        else
          "working days only"
        end
      end

      def parse(raw_value)
        case raw_value.downcase.strip
        when "all days", "true"
          true
        when "working days only", "false"
          false
        else
          raise "Invalid value for 'days counting' column: #{raw_value.strip.inspect}. " \
                "Expected 'all days' (ignore_non_working_days: true) " \
                "or 'working days only' (ignore_non_working_days: false)."
        end
      end
    end
  end
end
