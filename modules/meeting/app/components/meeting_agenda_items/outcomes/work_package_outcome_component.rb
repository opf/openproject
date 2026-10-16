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

module MeetingAgendaItems::Outcomes
  class WorkPackageOutcomeComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    attr_reader :meeting_outcome, :agenda_item, :meeting, :index

    def initialize(meeting_outcome:, index:)
      super

      @meeting_outcome = meeting_outcome
      @agenda_item = meeting_outcome.meeting_agenda_item
      @meeting = @agenda_item.meeting
      @index = index
    end

    private

    def wrapper_uniq_by
      @meeting_outcome.id
    end

    def multiple_outcomes?
      agenda_item.outcomes.size > 1
    end

    def edit_enabled?
      meeting.in_progress? &&
        User.current.allowed_in_project?(:manage_outcomes, meeting.project) &&
        !agenda_item.in_backlog?
    end

    def in_backlog?
      agenda_item.meeting_section.backlog?
    end

    def copy_action_item(menu)
      return if in_backlog?

      url = meeting_url(meeting, anchor: "outcome-#{meeting_outcome.id}")
      menu.with_item(label: t("button_copy_link_to_clipboard"),
                     tag: :"clipboard-copy",
                     content_arguments: { value: url }) do |item|
        item.with_leading_visual_icon(icon: :copy)
      end
    end

    def delete_action_item(menu)
      return unless edit_enabled?

      menu.with_item(label: t("label_agenda_outcome_delete"),
                     tag: :button,
                     scheme: :danger,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: project_meeting_agenda_item_outcome_path(
                         meeting.project,
                         meeting,
                         agenda_item,
                         meeting_outcome
                       ),
                       method: "DELETE",
                       confirm_message: t(:text_are_you_sure)
                     } }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
