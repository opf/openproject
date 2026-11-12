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
    # Column to specify scheduling mode of a work package.
    #
    # Can take values 'manual' or 'automatic' to set `schedule_manually`
    # attribute to `true` or `false` respectively.
    #
    # Example:
    #
    #   | subject | scheduling mode |
    #   | wp 1    | manual          |
    #   | wp 2    | automatic       |
    class SchedulingMode < Generic
      def format(value)
        if value
          "manual"
        else
          "automatic"
        end
      end

      def parse(raw_value)
        case raw_value.downcase.strip
        when ""
          nil
        when "manual", "true"
          true
        when "automatic", "false"
          false
        else
          raise "Invalid scheduling mode: #{raw_value.strip}. " \
                "Expected 'manual' or 'automatic'."
        end
      end
    end
  end
end
