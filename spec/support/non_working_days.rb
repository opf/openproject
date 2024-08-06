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

def week_with_saturday_and_sunday_as_non_working_day(monday: Date.current.monday, weeks_size: 4)
  weeks_size.times.map do |week_count|
    [
      create(:non_working_day, date: monday.next_occurring(:saturday) + week_count.weeks),
      create(:non_working_day, date: monday.next_occurring(:sunday) + week_count.weeks)
    ]
  end.flatten.pluck(:date)
end

def week_without_non_working_days(monday: Date.current.monday, weeks_size: 4)
  NonWorkingDay.where(date: monday...monday + weeks_size.weeks).destroy_all
end

def set_non_working_days(*dates)
  dates.map { |date| create(:non_working_day, date:) }
end

def set_working_days(*dates)
  NonWorkingDay.where(date: dates).destroy_all
end
