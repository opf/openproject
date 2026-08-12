# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2025 the OpenProject GmbH
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
# ++

# The module is not called I18n as that leads to tons of conflicts
# where I18n is called within the OpenProject module and rails I18n is meant.

module OpenProject
  module Internationalization
    module Date
      module_function
      WEEKDAY_NAMES = ::Date::DAYNAMES.map(&:downcase).freeze

      def self.beginning_of_week
        case (Setting.start_of_week || ::I18n.t(:general_first_day_of_week)).to_i
        when 1
          :monday
        when 7
          :sunday
        when 6
          :saturday
        else
          ::Date.beginning_of_week
        end
      end

      def time_at_beginning_of_week
        Time.current.at_beginning_of_week(beginning_of_week)
      end

      def ordered_weekdays
        start_index = WEEKDAY_NAMES.index(beginning_of_week.to_s) || 0

        WEEKDAY_NAMES.rotate(start_index)
      end
    end
  end
end
