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
  class Participants::AttendedToggleButtonComponent < ApplicationComponent
    include ApplicationHelper
    include OpenProject::FormTagHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, participant:)
      super

      @meeting = meeting
      @participant = participant
    end

    def call
      render(
        Primer::Beta::Button.new(
          tag: :a,
          href: toggle_attendance_project_meeting_participant_path(@meeting.project, @meeting, @participant),
          data: {
            turbo_method: :post,
            test_selector: "attendance_button_#{@participant.user_id}"
          },
          align_self: :center
        )
      ) do |button|
        button.with_leading_visual_icon(icon:)
        label
      end
    end

    private

    def icon
      @participant.attended? ? :check : "op-person-assigned"
    end

    def label
      key = @participant.attended? ? "attended" : "mark_as_attended"
      I18n.t("meeting.participants.label.#{key}")
    end
  end
end
