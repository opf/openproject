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

class MeetingAgendaItemsController < ApplicationController
  include AttachableServiceCall
  include OpTurbo::ComponentStream
  include Meetings::AgendaComponentStreams
  include ApplicationComponentStreams

  before_action :set_meeting
  before_action :set_agenda_item_type, only: %i[new create]
  before_action :set_meeting_agenda_item,
                except: %i[new cancel_new create]
  before_action :authorize

  def new
    if @meeting.open?
      if params[:meeting_section_id].present?
        meeting_section = @meeting.sections.find(params[:meeting_section_id])
      end
      render_agenda_item_form_via_turbo_stream(meeting_section:, type: @agenda_item_type)
    else
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    end

    respond_with_turbo_streams
  end

  def cancel_new
    if params[:meeting_section_id].present?
      meeting_section = @meeting.sections.find(params[:meeting_section_id])
      if meeting_section.agenda_items.empty?
        update_section_via_turbo_stream(form_hidden: true, meeting_section:)
      else
        update_new_button_via_turbo_stream(disabled: false, meeting_section:)
      end
    end

    update_new_component_via_turbo_stream(hidden: true, meeting_section:)
    update_new_button_via_turbo_stream(disabled: false)

    respond_with_turbo_streams
  end

  def create # rubocop:disable Metrics/AbcSize
    call = ::MeetingAgendaItems::CreateService
      .new(user: current_user)
      .call(
        meeting_agenda_item_params.merge(
          meeting_id: @meeting.id,
          item_type: @agenda_item_type.presence || MeetingAgendaItem::ITEM_TYPES[:simple]
        )
      )

    @meeting_agenda_item = call.result

    if call.success?
      reset_meeting_from_agenda_item
      # enable continue editing
      add_item_via_turbo_stream(clear_slate: false)
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream
    else
      # show errors
      update_new_component_via_turbo_stream(
        hidden: false, meeting_agenda_item: @meeting_agenda_item, type: @agenda_item_type
      )
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def edit
    if @meeting_agenda_item.editable?
      update_item_via_turbo_stream(state: :edit, display_notes_input: params[:display_notes_input])
    else
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    end

    respond_with_turbo_streams
  end

  def cancel_edit
    update_item_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def update
    call = ::MeetingAgendaItems::UpdateService
      .new(user: current_user, model: @meeting_agenda_item)
      .call(meeting_agenda_item_params)

    if call.success?
      reset_meeting_from_agenda_item
      update_item_via_turbo_stream
      update_section_header_via_turbo_stream(meeting_section: @meeting_agenda_item.meeting_section)
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream
    else
      # show errors
      update_item_via_turbo_stream(state: :edit)
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def destroy
    section = @meeting_agenda_item.meeting_section

    call = ::MeetingAgendaItems::DeleteService
      .new(user: current_user, model: @meeting_agenda_item)
      .call

    if call.success?
      reset_meeting_from_agenda_item
      remove_item_via_turbo_stream(clear_slate: @meeting.agenda_items.empty?)
      update_header_component_via_turbo_stream
      update_section_header_via_turbo_stream(meeting_section: section) if section&.reload.present?
      update_sidebar_details_component_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def drop
    call = ::MeetingAgendaItems::DropService.new(
      user: current_user, meeting_agenda_item: @meeting_agenda_item
    ).call(
      target_id: params[:target_id],
      position: params[:position]
    )

    if call.success?
      if call.result[:section_changed]
        move_item_to_other_section_via_turbo_stream(
          old_section: call.result[:old_section],
          current_section: call.result[:current_section]
        )
      else
        move_item_within_section_via_turbo_stream
      end
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def move
    call = ::MeetingAgendaItems::UpdateService
      .new(user: current_user, model: @meeting_agenda_item)
      .call(move_to: params[:move_to]&.to_sym)

    if call.success?
      move_item_within_section_via_turbo_stream
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
  def reset_meeting_from_agenda_item
    @meeting = @meeting_agenda_item.meeting
  end

  def set_agenda_item_type
    @agenda_item_type = params[:type]&.to_sym
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = MeetingAgendaItem.find(params[:id])
  end

  def meeting_agenda_item_params
    params
      .require(:meeting_agenda_item)
      .permit(:title, :duration_in_minutes, :presenter_id, :notes, :work_package_id, :lock_version, :meeting_section_id)
  end

  def generic_call_failure_response(call)
    # A failure might imply that the meeting was already closed and the action was triggered from a stale browser window
    # updating all components resolves the stale state of that window
    update_all_via_turbo_stream
    # show additional base error message
    render_base_error_in_flash_message_via_turbo_stream(call.errors)
  end
end
