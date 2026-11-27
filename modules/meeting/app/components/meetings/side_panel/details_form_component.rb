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

module Meetings
  class SidePanel::DetailsFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
      @project = meeting.project
    end

    def render?
      User.current.allowed_in_project?(:edit_meetings, @project)
    end

    private

    def start_date_initial_value
      format_date(@meeting.start_time, format: "%Y-%m-%d")
    end

    def start_time_initial_value
      format_time(@meeting.start_time, include_date: false, format: "%H:%M")
    end
  end
end
