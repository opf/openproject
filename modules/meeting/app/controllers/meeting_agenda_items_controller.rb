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

class MeetingAgendaItemsController < ApplicationController
  include AttachableServiceCall
  include OpTurbo::ComponentStream
  include AgendaComponentStreams
  include ApplicationComponentStreams

  before_action :set_meeting
  before_action :set_agenda_item_type, only: %i[new create]
  before_action :set_meeting_agenda_item,
                except: %i[index new cancel_new create author_autocomplete_index]
  before_action :authorize

  def new
    if @meeting.open?
      update_new_component_via_turbo_stream(hidden: false, type: @agenda_item_type)
      update_new_button_via_turbo_stream(disabled: true)
    else
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    end

    respond_with_turbo_streams
  end

  def cancel_new
    update_new_component_via_turbo_stream(hidden: true)
    update_new_button_via_turbo_stream(disabled: false)

    respond_with_turbo_streams
  end

  def create
    call = ::MeetingAgendaItems::CreateService
      .new(user: current_user)
      .call(meeting_agenda_item_params.merge(meeting_id: @meeting.id))

    @meeting_agenda_item = call.result

    if call.success?
      # enabel continue editing
      update_list_via_turbo_stream(form_hidden: false, form_type: @agenda_item_type)
      update_header_component_via_turbo_stream
    elsif call.errors[:base].present?
      render_base_error_in_flash_message_via_turbo_stream(call)
    else
      # show errors
      update_new_component_via_turbo_stream(
        hidden: false, meeting_agenda_item: @meeting_agenda_item, type: @agenda_item_type
      )
    end

    respond_with_turbo_streams
  end

  def edit
    if @meeting_agenda_item.editable?
      update_item_via_turbo_stream(state: :edit)
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
      update_item_via_turbo_stream
      update_header_component_via_turbo_stream
    elsif call.errors[:base].present?
      render_base_error_in_flash_message_via_turbo_stream(call)
    else
      # show errors
      update_item_via_turbo_stream(state: :edit)
      render_base_error_in_flash_message_via_turbo_stream(call)
    end

    respond_with_turbo_streams
  end

  def destroy
    call = ::MeetingAgendaItems::DeleteService
      .new(user: current_user, model: @meeting_agenda_item)
      .call

    if call.success?
      update_list_via_turbo_stream
      update_header_component_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def drop
    call = ::MeetingAgendaItems::UpdateService
      .new(user: current_user, model: @meeting_agenda_item)
      .call(position: params[:position].to_i)

    if call.success?
      update_list_via_turbo_stream
      update_header_component_via_turbo_stream
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
      update_list_via_turbo_stream
      update_header_component_via_turbo_stream
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  # Primer's autocomplete displays the ID of a user when selected instead of the name
  # this cannot be changed at the moment as the component uses a simple text field which
  # can't differentiate between a display and submit value
  # thus, we can't use it
  # leaving the code here for future reference
  # def author_autocomplete_index
  #   @users = User.active.like(params[:q]).limit(10)

  #   render(Authors::AutocompleteItemComponent.with_collection(@users), layout: false)
  # end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
    @project = @meeting.project # required for authorization via before_action
  end

  def set_agenda_item_type
    @agenda_item_type = params[:type]&.to_sym
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = MeetingAgendaItem.find(params[:id])
  end

  def meeting_agenda_item_params
    params.require(:meeting_agenda_item).permit(:title, :duration_in_minutes, :description, :author_id, :work_package_id)
  end

  def generic_call_failure_response(call)
    # A failure might imply that the meeting was already closed and the action was triggered from a stale browser window
    # updating all components resolves the stale state of that window
    update_all_via_turbo_stream
    # show additional base error message
    render_base_error_in_flash_message_via_turbo_stream(call)
  end

  def render_base_error_in_flash_message_via_turbo_stream(call)
    if call.errors[:base].present?
      render_error_flash_message_via_turbo_stream(message: call.errors[:base].to_sentence)
    end
  end
end
