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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class MeetingAgendaItemVotesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include Meetings::AgendaComponentStreams

  load_and_authorize_with_permission_in_project :view_meetings
  before_action :set_agenda_item

  def create
    call = MeetingAgendaItems::VoteService
      .new(user: current_user, meeting_agenda_item: @meeting_agenda_item)
      .call(reaction: params[:reaction])

    if call.success?
      update_vote_components
    else
      render_error_flash_message_via_turbo_stream(message: call.message)
    end

    respond_with_turbo_streams
  end

  private

  def set_agenda_item
    @meeting = @project.meetings.visible.find(params.expect(:meeting_id))
    @meeting_agenda_item = @meeting.agenda_items.find(params.expect(:agenda_item_id))
  end

  def update_vote_components
    @meeting.reload
    update_via_turbo_stream(
      component: MeetingSections::ShowComponent.new(meeting_section: @meeting_agenda_item.meeting_section.reload),
      method: "morph"
    )
    update_header_component_via_turbo_stream
  end
end
