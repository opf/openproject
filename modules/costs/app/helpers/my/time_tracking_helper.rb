# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTrackingHelper
    def week_date_range(date)
      date_range(week_days(date).first, week_days(date).last)
    end

    # The work week leaves out the days that are not worked, so it is the range it covers
    # rather than the week around it that names it.
    def workweek_date_range(date)
      date_range(workweek_days(date).first, workweek_days(date).last)
    end

    def week_days(date)
      date.all_week(OpenProject::Internationalization::Date.beginning_of_week)
    end

    def workweek_days(date)
      worked = Setting.working_days.map { |day| day % 7 }

      week_days(date).select { |day| worked.include?(day.wday) }
    end

    def date_range(from, to)
      if from.year == to.year && from.month == to.month
        [I18n.l(from, format: "%d."), I18n.l(to, format: "%d. %B %Y")].join(" - ")
      elsif from.year == to.year
        [I18n.l(from, format: "%d. %B"), I18n.l(to, format: "%d. %B %Y")].join(" - ")
      else
        [I18n.l(from, format: "%d. %B %Y"), I18n.l(to, format: "%d. %B %Y")].join(" - ")
      end
    end
  end
end
