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

class MeetingAgendaItemsController < ApplicationController
  include AttachableServiceCall
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include Meetings::AgendaComponentStreams

  load_and_authorize_with_permission_in_project :manage_agendas
  authorize_with_permission :add_work_packages,
                            only: %i[convert_to_work_package_dialog
                                     convert_to_work_package
                                     refresh_convert_to_work_package_dialog]

  before_action :set_meeting
  before_action :set_agenda_item_type, only: %i[new create]
  before_action :set_meeting_agenda_item,
                except: %i[new cancel_new create]
  before_action :set_current_occurrence,
                :set_presentation_mode,
                only: %i[new cancel_new edit cancel_edit create update destroy drop move move_to_section_dialog
                         convert_to_work_package]
  before_action :check_recurring_meeting_param,
                only: %i[move_to_next_meeting move_to_next_meeting_dialog duplicate_in_next_meeting
                         duplicate_in_next_meeting_dialog]
  before_action :assign_drop_params, only: %i[drop]

  def new
    if @meeting.closed?
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    else
      if params[:meeting_section_id].present?
        meeting_section = MeetingSection.find_by(id: params[:meeting_section_id])
        if meeting_section.backlog?
          collapsed = false
        end
      end
      render_agenda_item_form_via_turbo_stream(meeting_section:, collapsed:, type: @agenda_item_type,
                                               current_occurrence: @current_occurrence)
    end

    respond_with_turbo_streams
  end

  def cancel_new
    if params[:meeting_section_id].present?
      meeting_section = MeetingSection.find_by(id: params[:meeting_section_id])
      if meeting_section.agenda_items.empty?
        if meeting_section.backlog?
          collapsed = false
        end
        update_section_via_turbo_stream(form_hidden: true, meeting_section:, collapsed:, current_occurrence: @current_occurrence)
      end
    end

    update_new_component_via_turbo_stream(hidden: true, meeting_section:, current_occurrence: @current_occurrence)
    update_new_button_via_turbo_stream(disabled: false) unless meeting_section&.backlog?

    respond_with_turbo_streams
  end

  def edit
    if @meeting_agenda_item.editable?
      update_item_via_turbo_stream(state: :edit,
                                   display_notes_input: params[:display_notes_input],
                                   presentation_mode: @presentation_mode,
                                   current_occurrence: @current_occurrence)
    else
      update_all_via_turbo_stream
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
    end

    respond_with_turbo_streams
  end

  def cancel_edit
    update_item_via_turbo_stream(state: :show,
                                 current_occurrence: @current_occurrence,
                                 presentation_mode: @presentation_mode)

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
      if @meeting_agenda_item.meeting_section.backlog?
        update_section_via_turbo_stream(meeting_section: @meeting_agenda_item.meeting_section, collapsed: false,
                                        current_occurrence: @current_occurrence)
      else
        reset_meeting_from_agenda_item
        # enable continue editing
        update_header_component_via_turbo_stream
        update_sidebar_details_component_via_turbo_stream
        add_item_via_turbo_stream(clear_slate: false, current_occurrence: @current_occurrence)
      end
    else
      # show errors
      update_new_component_via_turbo_stream(
        hidden: false, meeting_agenda_item: @meeting_agenda_item, type: @agenda_item_type, current_occurrence: @current_occurrence
      )
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def update
    call = update_agenda_item(meeting_agenda_item_params)

    if call.success?
      unless @meeting_agenda_item.meeting_section.backlog?
        reset_meeting_from_agenda_item
        update_header_component_via_turbo_stream
        update_sidebar_details_component_via_turbo_stream
      end
      update_item_via_turbo_stream(current_occurrence: @current_occurrence,
                                   presentation_mode: @presentation_mode)
      update_section_header_via_turbo_stream(meeting_section: @meeting_agenda_item.meeting_section)
    else
      # show errors
      update_item_via_turbo_stream(state: :edit,
                                   current_occurrence: @current_occurrence,
                                   presentation_mode: @presentation_mode)
      render_base_error_in_flash_message_via_turbo_stream(call.errors)
    end

    respond_with_turbo_streams
  end

  def destroy # rubocop:disable Metrics/AbcSize
    section = @meeting_agenda_item.meeting_section

    call = ::MeetingAgendaItems::DeleteService
      .new(user: current_user, model: @meeting_agenda_item)
      .call

    if call.success?
      if section.backlog?
        update_section_via_turbo_stream(meeting_section: section, collapsed: false, current_occurrence: @current_occurrence)
      else
        reset_meeting_from_agenda_item
        update_header_component_via_turbo_stream
        update_sidebar_details_component_via_turbo_stream
        remove_item_via_turbo_stream(clear_slate: @meeting.agenda_items.empty?, current_occurrence: @current_occurrence)

        # If section is deleted via an after_destroy/after_update action, it needs to be handled separately
        if MeetingSection.exists?(section.id) && section&.reload.present?
          update_section_header_via_turbo_stream(meeting_section: section)
        end
      end
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def drop
    @meeting = @current_occurrence if @current_occurrence.present?

    call = if @target_id.nil?
             update_agenda_item(meeting: @current_occurrence, meeting_section: nil)
           else
             ::MeetingAgendaItems::DropService
               .new(user: current_user, meeting_agenda_item: @meeting_agenda_item)
               .call(target_id: @target_id, position: @position)
           end

    handle_agenda_item_update_on_move(call)
  end

  def move
    @meeting = @current_occurrence if @current_occurrence.present?

    call = update_agenda_item(move_to: params[:move_to]&.to_sym)

    if call.success?
      update_agenda_via_turbo_stream
      update_header_component_via_turbo_stream
      update_backlog_via_turbo_stream(collapsed: ActiveModel::Type::Boolean.new.cast(params[:collapsed]))
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end

  def move_to_next_meeting_dialog
    next_occurrence = init_next_meeting_occurrence
    return if next_occurrence.nil?

    respond_with_dialog MeetingAgendaItems::MoveToNextMeetingDialogComponent.new(
      agenda_item: @meeting_agenda_item,
      datetime: params[:datetime],
      skipped_cancelled: params[:skipped_cancelled],
      skipped_closed: params[:skipped_closed],
      next_occurrence:
    )
  end

  def duplicate_in_next_meeting_dialog
    next_occurrence = init_next_meeting_occurrence
    return if next_occurrence.nil?

    respond_with_dialog MeetingAgendaItems::DuplicateInNextMeetingDialogComponent.new(
      agenda_item: @meeting_agenda_item,
      datetime: params[:datetime],
      skipped_cancelled: params[:skipped_cancelled],
      skipped_closed: params[:skipped_closed],
      next_occurrence:
    )
  end

  def move_to_next_meeting
    next_occurrence = init_next_meeting_occurrence
    return if next_occurrence.nil?

    update_call = update_agenda_item(
      meeting_id: next_occurrence.id,
      meeting_section_id: params.dig(:meeting_agenda_item, :meeting_section_id)
    )

    if update_call.success?
      render_next_meeting_flash(:text_agenda_item_moved_to_next_meeting, next_occurrence)
      remove_item_via_turbo_stream(clear_slate: @meeting.agenda_items.empty?)
      update_header_component_via_turbo_stream
      respond_with_turbo_streams
    else
      respond_with_flash_error(message: update_call.message)
    end
  end

  def duplicate_in_next_meeting
    next_occurrence = init_next_meeting_occurrence
    return if next_occurrence.nil?

    duplicate_call = duplicate_agenda_item_in_meeting(next_occurrence)

    if duplicate_call.success?
      close_dialog_via_turbo_stream("#duplicate-in-next-meeting-dialog")
      render_next_meeting_flash(:text_agenda_item_duplicated_in_next_meeting, next_occurrence)
      update_header_component_via_turbo_stream
      respond_with_turbo_streams
    else
      respond_with_flash_error(message: duplicate_call.message)
    end
  end

  def move_to_section_dialog
    meeting = @current_occurrence || @meeting_agenda_item.meeting

    respond_with_dialog MeetingAgendaItems::MoveToSectionDialogComponent.new(
      agenda_item: @meeting_agenda_item,
      meeting:,
      collapsed: params[:collapsed]
    )
  end

  def convert_to_work_package_dialog
    work_package = convert_to_work_package_service
      .build_work_package(meeting_agenda_item: @meeting_agenda_item)

    respond_with_dialog MeetingAgendaItems::ConvertToWorkPackage::CreateDialogComponent.new(
      work_package:,
      project: @project,
      meeting: @meeting,
      meeting_agenda_item: @meeting_agenda_item
    )
  end

  def refresh_convert_to_work_package_dialog
    work_package = convert_to_work_package_service
      .build_work_package(meeting_agenda_item: @meeting_agenda_item, params: permitted_params.update_work_package)

    form_component = MeetingAgendaItems::ConvertToWorkPackage::CreateFormComponent.new(
      work_package:,
      project: @project,
      meeting: @meeting,
      meeting_agenda_item: @meeting_agenda_item
    )

    update_via_turbo_stream(component: form_component)
    respond_with_turbo_streams
  end

  def convert_to_work_package
    call = convert_to_work_package_service.call(
      meeting_agenda_item: @meeting_agenda_item,
      work_package_params: permitted_params.update_work_package
    )

    if call.success?
      reset_meeting_from_agenda_item
      update_item_via_turbo_stream(current_occurrence: @current_occurrence,
                                   presentation_mode: @presentation_mode)
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream
    else
      form_component = MeetingAgendaItems::ConvertToWorkPackage::CreateFormComponent.new(
        work_package: call.result,
        project: @project,
        meeting: @meeting,
        meeting_agenda_item: @meeting_agenda_item
      )
      update_via_turbo_stream(component: form_component, status: :bad_request)
    end

    respond_with_turbo_streams
  end

  def move_to_section
    section_scope = if @meeting.recurring_meeting_id.present?
                      MeetingSection.joins(:meeting).where(meetings: { recurring_meeting_id: @meeting.recurring_meeting_id })
                    else
                      @meeting.sections
                    end
    meeting_section = section_scope.find_by(id: params[:meeting_agenda_item][:meeting_section_id])
    @meeting = meeting_section.meeting unless meeting_section.backlog?

    call = update_agenda_item(meeting_section:)

    handle_agenda_item_update_on_move(call)
  end

  private

  def convert_to_work_package_service
    @convert_to_work_package_service ||=
      ::MeetingAgendaItems::ConvertToWorkPackageService.new(user: current_user, project: @project)
  end

  def update_agenda_item(params)
    ::MeetingAgendaItems::UpdateService
      .new(user: current_user, model: @meeting_agenda_item)
      .call(params)
  end

  def duplicate_agenda_item_in_meeting(target_meeting)
    attributes = @meeting_agenda_item.copy_attributes
    attributes = attributes.except("author_id", "created_at", "updated_at", "lock_version", "position")

    attributes[:meeting_id] = target_meeting.id
    attributes[:meeting_section_id] = MeetingSection.find_by(id: params.dig(:meeting_agenda_item, :meeting_section_id))&.id
    attributes[:source_meeting_id] = @meeting_agenda_item.meeting_id

    ::MeetingAgendaItems::CreateService
      .new(user: current_user)
      .call(attributes)
  end

  def init_next_meeting_occurrence
    return @next_occurrence if @next_occurrence.present?

    call = ::RecurringMeetings::InitOccurrenceService
    .new(user: User.system, recurring_meeting: @series)
    .call(start_time: @next_meeting_time)

    if call.success?
      call.result
    else
      respond_with_flash_error(message: call.message)
      nil
    end
  end

  def set_meeting
    @meeting = @project.meetings.visible.find(params[:meeting_id])
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
    @meeting_agenda_item = @meeting.agenda_items.find(params[:id])
  end

  def set_current_occurrence
    @current_occurrence = Meeting.visible.find_by(id: params[:current_occurrence])
  end

  def set_presentation_mode
    @presentation_mode = ActiveModel::Type::Boolean.new.cast(params[:presentation_mode])
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

  def check_recurring_meeting_param
    if @meeting.closed? || !@meeting.recurring?
      return render_400
    end

    @next_meeting_time = DateTime.iso8601(params[:datetime]).utc
    @series = @meeting.recurring_meeting

    render_400 unless @next_meeting_time && @series.occurs_at?(@next_meeting_time)
    find_existing_occurrence
  end

  def find_existing_occurrence
    next_occurrence = @series.meetings.not_templated.find_by(recurrence_start_time: @next_meeting_time)

    if next_occurrence&.cancelled? || next_occurrence&.closed?
      result = @series.first_available_occurrence(from_time: @next_meeting_time)

      if result.nil?
        return respond_with_flash_error(message: I18n.t(:text_agenda_item_no_available_occurrence))
      end

      @next_meeting_time = result[:occurrence]
      next_occurrence = @series.meetings.not_templated.find_by(recurrence_start_time: @next_meeting_time)
    end

    @next_occurrence = next_occurrence&.cancelled? ? nil : next_occurrence
  end

  def render_next_meeting_flash(base_key, next_occurrence)
    flash = OpPrimer::FlashComponent.new(scheme: :success)
    flash.with_content(I18n.t(base_key, date: format_date(next_occurrence.start_time)))
    flash.with_action_button(tag: :a, href: project_meeting_path(next_occurrence.project, next_occurrence)) do
      I18n.t(:label_view_meeting)
    end

    turbo_streams << flash.render_as_turbo_stream(view_context:, action: :flash)
  end

  def assign_drop_params # rubocop:disable Metrics/AbcSize
    @target_id, @position =
      if params[:type] == "to_current"
        meeting = @current_occurrence
        section = meeting.sections.reorder(position: :desc).first
        [section&.id, section&.last_position]
      elsif params[:type] == "to_backlog"
        [@meeting.backlog.id, @meeting.backlog.last_position]
      else
        [params[:target_id], params[:position]]
      end
  end

  def assign_drop_results(call, meeting_agenda_item_section)
    if @target_id.nil?
      old_section     = meeting_agenda_item_section
      current_section = call.result.meeting_section
      section_changed = true
    else
      old_section     = call.result[:old_section]
      current_section = call.result[:current_section]
      section_changed = call.result[:section_changed]
    end

    [old_section, current_section, section_changed]
  end

  def handle_agenda_item_update_on_move(call)
    if call.success?
      update_all_via_turbo_stream
      update_backlog_via_turbo_stream(collapsed: ActiveModel::Type::Boolean.new.cast(params[:collapsed]))
    else
      generic_call_failure_response(call)
    end

    respond_with_turbo_streams
  end
end
