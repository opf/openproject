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

class MeetingSectionsController < ApplicationController
  include AttachableServiceCall
  include OpTurbo::ComponentStream
  include Meetings::AgendaComponentStreams
  include ApplicationComponentStreams

  before_action :set_meeting
  before_action :set_meeting_section,
                except: %i[create]
  before_action :authorize

  def create # rubocop:disable Metrics/AbcSize
    call = ::MeetingSections::CreateService
      .new(user: current_user)
      .call(
        {
          meeting_id: @meeting.id
        }
      )

    @meeting_section = call.result

    if call.success?
      reset_meeting_from_agenda_section
      add_section_via_turbo_stream
      update_section_via_turbo_stream(force_wrapper: true, state: :edit)
      # update the section header of the previously last section in order to ensure the action menu move options are updated
      update_section_header_via_turbo_stream(meeting_section: @meeting.sections.last(2).first) if @meeting.sections.count > 1
      update_new_button_via_turbo_stream(disabled: true)
      update_header_component_via_turbo_stream
    else
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def edit
    if @meeting_section.editable?
      update_section_header_via_turbo_stream(state: :edit)
    else
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    end

    respond_with_turbo_streams
  end

  def cancel_edit
    if @meeting_section.untitled? && @meeting_section.agenda_items.empty?
      # if the section is untitled and no agenda items, we can safely delete it
      destroy and return
    else
      update_section_header_via_turbo_stream(state: :show)
      update_new_button_via_turbo_stream(disabled: false)
    end

    respond_with_turbo_streams
  end

  def update
    call = ::MeetingSections::UpdateService
      .new(user: current_user, model: @meeting_section)
      .call(meeting_section_params)

    if call.success?
      reset_meeting_from_agenda_section
      update_section_header_via_turbo_stream(state: :show)
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream
      update_new_button_via_turbo_stream(disabled: false)
    else
      # show errors
      update_section_header_via_turbo_stream(state: :edit)
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def destroy
    call = ::MeetingSections::DeleteService
      .new(user: current_user, model: @meeting_section)
      .call

    if call.success?
      reset_meeting_from_agenda_section
      remove_section_via_turbo_stream
      # in case the destroy action was called from the cancel_edit action
      # we need to update the new button state, which was disabled before
      update_new_button_via_turbo_stream(disabled: false)
      # update all section headers in order to ensure the action menu move options are updated
      update_section_headers_via_turbo_stream
      update_header_component_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def drop
    call = ::MeetingSections::UpdateService
      .new(user: current_user, model: @meeting_section, contract_class: MeetingSections::MoveContract)
      .call(position: params[:position].to_i)

    if call.success?
      # the DOM is already updated on the client-side through the drag
      # in order to preserve an edit state within the section,
      # we don't send a server-side rendered update via `move_section_via_turbo_stream`
      # update all section headers in order to ensure the action menu move options are updated
      update_section_headers_via_turbo_stream
      # update all time slots as a section position change affects potentially all time slots
      update_show_items_via_turbo_stream
      update_header_component_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def move
    call = ::MeetingSections::UpdateService
      .new(user: current_user, model: @meeting_section, contract_class: MeetingSections::MoveContract)
      .call(move_to: params[:move_to]&.to_sym)

    if call.success?
      move_section_via_turbo_stream
      # CODE MAINTENANCE: edit state within the moved section potentially gets lost
      # unlike at the drop action, we need to send server-side rendered updates in order to reflect the new position
      # thus an edit state inside the section gets lost
      update_header_component_via_turbo_stream
      # update all section headers in order to ensure the action menu move options are updated
      update_section_headers_via_turbo_stream
      # update all time slots as a section position change affects potentially all time slots
      update_show_items_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
    @project = @meeting.project # required for authorization via before_action
  end

  # In case we updated the meeting as part of the service flow
  # it needs to be reassigned for the controller in order to get correct timestamps
  def reset_meeting_from_agenda_section
    @meeting = @meeting_section.meeting
  end

  def set_agenda_item_type
    @agenda_item_type = params[:type]&.to_sym
  end

  def set_meeting_section
    @meeting_section = MeetingSection.find(params[:id])
  end

  def meeting_section_params
    params
      .require(:meeting_section)
      .permit(:title)
  end

  def generic_call_failure_response(call)
    # A failure might imply that the meeting was already closed and the action was triggered from a stale browser window
    # updating all components resolves the stale state of that window
    update_all_via_turbo_stream
    # show additional base error message
    render_base_error_in_flash_message_via_turbo_stream(call.errors)
  end
end
