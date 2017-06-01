#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Provides helper methods for a project's calendar view.
module CalendarsHelper
  # Generates a html link to a calendar of the previous month.
  # @param [Integer] year the current year
  # @param [Integer] month the current month
  # @param [Hash, nil] options html options passed to the link generation
  # @return [String] link to the calendar
  def link_to_previous_month(year, month, options = {})
    target_date = Date.new(year, month, 1) - 1.month
    link_to_month(target_date, options.merge(class: 'navigate-left',
                                             display_year: target_date.year != year))
  end

  # Generates a html link to a calendar of the next month.
  # @param [Integer] year the current year
  # @param [Integer] month the current month
  # @param [Hash, nil] options html options passed to the link generation
  # @return [String] link to the calendar
  def link_to_next_month(year, month, options = {})
    target_date = Date.new(year, month, 1) + 1.month
    link_to_month(target_date, options.merge(class: 'navigate-right',
                                             display_year: target_date.year != year))
  end

  # Generates a html-link which leads to a calendar displaying the given date.
  # @param [Date, Time] date the date which should be displayed
  # @param [Hash, nil] options html options passed to the link generation
  # @options options [Boolean] :display_year Whether the year should be displayed
  # @return [String] link to the calendar
  def link_to_month(date_to_show, options = {})
    date = date_to_show.to_date
    name = ::I18n.l date, format: options.delete(:display_year) ? '%B %Y' : '%B'

    merged_params = permitted_params
                    .calendar_filter
                    .merge(year: date.year, month: date.month)

    link_to_content_update(name, merged_params, options)
  end
end
