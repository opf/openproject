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
    def week_date_range(date) # rubocop:disable Metrics/AbcSize
      start_day = OpenProject::Internationalization::Date.beginning_of_week
      bow = date.beginning_of_week(start_day)
      eow = date.end_of_week(start_day)

      if bow.year == eow.year && bow.month == eow.month
        [I18n.l(bow, format: "%d."), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
      elsif bow.year == eow.year
        [I18n.l(bow, format: "%d. %B"), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
      else
        [I18n.l(bow, format: "%d. %B %Y"), I18n.l(eow, format: "%d. %B %Y")].join(" - ")
      end
    end
  end
end
