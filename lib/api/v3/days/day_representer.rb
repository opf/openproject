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

module API::V3::Days
  class DayRepresenter < ::API::Decorators::Single
    property :date
    property :name
    property :working

    self_link path: :day, id_attribute: :date

    link :weekday do
      {
        href: api_v3_paths.days_week_day(represented.day_of_week),
        title: represented.name
      }
    end

    links :nonWorkingReasons do
      next if represented.working

      links = []
      unless represented.week_day.working
        links << {
          title: represented.name,
          href: api_v3_paths.days_week_day(represented.week_day.day)
        }
      end

      represented.non_working_days.each do |day|
        links << { title: day.name, href: api_v3_paths.days_non_working_day(day.date) }
      end
      links
    end

    def _type
      "Day"
    end
  end
end
