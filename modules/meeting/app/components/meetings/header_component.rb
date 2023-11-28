#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Meetings
  class HeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, state: :show)
      super

      @meeting = meeting
      @state = state
    end

    private

    def render_author_link
      render(Primer::Beta::Link.new(font_size: :small, href: user_path(@meeting.author), underline: false,
                                    target: "_blank")) do
        "#{@meeting.author.name}"
      end
    end

    def delete_enabled?
      User.current.allowed_in_project?(:delete_meetings, @meeting.project)
    end

    def last_updated_at
      latest_agenda_update = @meeting.agenda_items.maximum(:updated_at) || @meeting.updated_at
      latest_meeting_update = @meeting.updated_at

      [latest_agenda_update, latest_meeting_update].max
    end
  end
end
