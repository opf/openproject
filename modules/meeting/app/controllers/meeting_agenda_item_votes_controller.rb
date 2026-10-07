# frozen_string_literal: true

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
