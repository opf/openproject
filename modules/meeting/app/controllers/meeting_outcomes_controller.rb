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

class MeetingOutcomesController < ApplicationController
  include OpTurbo::ComponentStream
  include Meetings::AgendaComponentStreams

  load_and_authorize_with_permission_in_project :manage_outcomes
  authorize_with_permission :add_work_packages,
                            only: %i[create_work_package_dialog create_work_package refresh_work_package_dialog]

  before_action :set_meeting
  before_action :set_meeting_agenda_item
  before_action :set_meeting_outcome,
                except: %i[new cancel_new create create_work_package_dialog create_work_package refresh_work_package_dialog]

  def new
    update_meeting_metadata_via_turbo_stream

    if @meeting.in_progress? && !@meeting_agenda_item.in_backlog?
      component = build_outcome_form_component

      replace_via_turbo_stream(
        component:,
        target: MeetingAgendaItems::Outcomes::NewButtonComponent.component_id(@meeting_agenda_item)
      )
    else
      render_error_flash_message_via_turbo_stream(message: t("text_outcome_cannot_be_added"))
    end

    respond_with_turbo_streams
  end

  def cancel_new
    update_outcomes_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
    respond_with_turbo_streams
  end

  def edit
    if @meeting_outcome.editable?
      @meeting_agenda_item = @meeting_outcome.meeting_agenda_item
      replace_via_turbo_stream(
        component: MeetingAgendaItems::Outcomes::InputComponent.new(meeting: @meeting, meeting_agenda_item: @meeting_agenda_item,
                                                                    meeting_outcome: @meeting_outcome),
        target: MeetingAgendaItems::Outcomes::OutcomeComponent.component_id(@meeting_outcome)
      )

    else
      render_error_flash_message_via_turbo_stream(message: t("text_meeting_not_editable_anymore"))
      update_meeting_metadata_via_turbo_stream
    end

    respond_with_turbo_streams
  end

  def create
    call = ::MeetingOutcomes::CreateService
             .new(user: current_user)
             .call(create_outcome_params)

    @meeting_outcome = call.result

    if call.success?
      update_outcomes_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join("\n"))
    end

    update_meeting_metadata_via_turbo_stream
    respond_with_turbo_streams
  end

  def cancel_edit
    @meeting_agenda_item = @meeting_outcome.meeting_agenda_item
    update_outcomes_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)

    respond_with_turbo_streams
  end

  def update
    @meeting_agenda_item = @meeting_outcome.meeting_agenda_item
    call = ::MeetingOutcomes::UpdateService
             .new(user: current_user, model: @meeting_outcome)
             .call(
               meeting_agenda_item: @meeting_agenda_item,
               notes: params[:meeting_outcome][:notes]
             )

    if call.success?
      update_outcomes_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join("\n"))
    end

    update_meeting_metadata_via_turbo_stream

    respond_with_turbo_streams
  end

  def destroy
    @meeting_agenda_item = @meeting_outcome.meeting_agenda_item
    call = ::MeetingOutcomes::DeleteService
      .new(user: current_user, model: @meeting_outcome)
      .call

    if call.success?
      update_outcomes_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
      update_header_component_via_turbo_stream
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join("\n"))
    end

    update_meeting_metadata_via_turbo_stream

    respond_with_turbo_streams
  end

  def create_work_package_dialog
    work_package = create_work_package_service.build_work_package

    respond_with_dialog MeetingAgendaItems::Outcomes::CreateWorkPackageDialogComponent.new(
      work_package:,
      project: @project,
      meeting: @meeting,
      meeting_agenda_item: @meeting_agenda_item
    )
  end

  def refresh_work_package_dialog
    work_package = create_work_package_service.build_work_package(permitted_params.update_work_package)

    form_component = MeetingAgendaItems::Outcomes::CreateWorkPackageFormComponent.new(
      work_package:,
      project: @project,
      meeting: @meeting,
      meeting_agenda_item: @meeting_agenda_item
    )

    update_via_turbo_stream(component: form_component)
    respond_with_turbo_streams
  end

  def create_work_package # rubocop:disable Metrics/AbcSize
    call = create_work_package_service
      .call(meeting_agenda_item: @meeting_agenda_item, work_package_params: permitted_params.update_work_package)

    if call.success?
      update_all_via_turbo_stream
      scroll_into_view_via_turbo_stream("outcome-#{call.result.id}")
    elsif call.result.errors.any?
      # Work package creation failed
      form_component = MeetingAgendaItems::Outcomes::CreateWorkPackageFormComponent.new(
        work_package: call.result,
        project: @project,
        meeting: @meeting,
        meeting_agenda_item: @meeting_agenda_item
      )
      update_via_turbo_stream(component: form_component, status: :bad_request)
    else
      # Outcome creation failed
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.join("\n"))
    end

    respond_with_turbo_streams
  end

  private

  def set_meeting
    @meeting = @project.meetings.visible.find(params[:meeting_id])
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = @meeting.agenda_items.find(params[:agenda_item_id])
  end

  def set_meeting_outcome
    @meeting_outcome = if @meeting_agenda_item
                         @meeting_agenda_item.outcomes.find(params[:id])
                       else
                         MeetingOutcome
                         .joins(meeting_agenda_item: :meeting)
                         .where(meetings: { id: @meeting.id })
                         .find(params[:id])
                       end
  end

  def build_outcome_form_component
    component_class = if params[:kind] == "work_package"
                        MeetingAgendaItems::Outcomes::WorkPackageFormComponent
                      else
                        MeetingAgendaItems::Outcomes::InputComponent
                      end

    component_class.new(
      meeting: @meeting,
      meeting_agenda_item: @meeting_agenda_item,
      meeting_outcome: @meeting_agenda_item.outcomes.new
    )
  end

  def create_outcome_params
    if params[:meeting_outcome][:work_package_id].present?
      {
        meeting_agenda_item: @meeting_agenda_item,
        work_package_id: params[:meeting_outcome][:work_package_id],
        kind: :work_package
      }
    else
      {
        meeting_agenda_item: @meeting_agenda_item,
        notes: params[:meeting_outcome][:notes],
        kind: :information
      }
    end
  end

  def create_work_package_service
    @create_work_package_service ||= ::MeetingOutcomes::CreateWithWorkPackageService.new(user: current_user, project: @project)
  end
end
