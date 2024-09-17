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

module WorkPackages
  module Shared
    class AllDays
      # Returns number of days between two dates, inclusive.
      def duration(start_date, due_date)
        return nil unless start_date && due_date

        (start_date..due_date).count
      end

      def start_date(due_date, duration)
        return nil unless due_date && duration
        raise ArgumentError, "duration must be strictly positive" if duration.is_a?(Integer) && duration <= 0

        due_date - duration + 1
      end

      def due_date(start_date, duration)
        return nil unless start_date && duration
        raise ArgumentError, "duration must be strictly positive" if duration.is_a?(Integer) && duration <= 0

        start_date + duration - 1
      end

      def soonest_working_day(date, lag: nil)
        lag ||= 0
        date + lag.days if date
      end

      def working?(_date)
        true
      end
    end
  end
end
