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

module Meetings
  class SidePanel::ParticipantsComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    MAX_SHOWN_PARTICIPANTS = 5

    def wrapper_data_attributes
      {
        controller: "expandable-list",
        "application-target": "dynamic"
      }
    end

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def elements
      @elements ||= @meeting.invited_or_attended_participants.sort
    end

    def count
      @count ||= elements.count
    end

    def render_participant(participant)
      flex_layout(align_items: :center) do |flex|
        flex.with_column(classes: "ellipsis") do
          render(Users::AvatarComponent.new(user: participant.user,
                                            size: :medium,
                                            classes: "op-principal_flex"))
        end
        render_participant_state(participant, flex)
      end
    end

    def render_participant_state(participant, flex)
      if participant.attended?
        flex.with_column(ml: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("description_attended").capitalize }
        end
      elsif participant.invited?
        flex.with_column(ml: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("description_invite").capitalize }
        end
      end
    end
  end
end
