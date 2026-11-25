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

module My
  module Productivity
    class WeeklyProgressComponent < ApplicationComponent
      options :weekly_progress

      def bar_percentage(week)
        return 0 if max_completed.zero?

        (week.completed * 100.0 / max_completed).round
      end

      def week_label(week)
        helpers.format_date(week.week_start)
      end

      def total_completed
        weekly_progress.sum(&:completed)
      end

      def weekly_average
        (total_completed.to_f / weekly_progress.size).round(1)
      end

      private

      def max_completed
        @max_completed ||= weekly_progress.map(&:completed).max.to_i
      end
    end
  end
end
