# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Activities::DaysComponent < ViewComponent::Base
  def initialize(events:, current_project: nil, display_user: true, header_tag: 'h3', activity_page: nil)
    super()
    @events = events
    @current_project = current_project
    @display_user = display_user
    @header_tag = header_tag
    @activity_page = activity_page
  end

  def events_by_day_sorted_by_newest_first
    @events_by_day_sorted_by_newest_first ||= @events
      .group_by { |e| e.event_datetime.in_time_zone(User.current.time_zone).to_date }
      .transform_values { |events| events.sort { |x, y| y.event_datetime <=> x.event_datetime } }
      .sort_by { |day, _events| day }
      .reverse
  end
end
