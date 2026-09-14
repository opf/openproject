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

class WorkPackageMeetingsTabController < ApplicationController
  include OpTurbo::ComponentStream
  include Meetings::WorkPackageMeetingsTabComponentStreams

  load_and_authorize_with_permission_in_project :view_work_packages

  before_action :set_work_package

  def index
    direction = params[:direction]&.to_sym || :upcoming # default to upcoming

    set_agenda_items(direction)

    render(
      WorkPackageMeetingsTab::IndexComponent.new(
        direction:,
        work_package: @work_package,
        agenda_items_grouped_by_meeting: @agenda_items_grouped_by_meeting,
        upcoming_meetings_count: @upcoming_meetings_count,
        past_meetings_count: @past_meetings_count
      ),
      layout: false
    )
  end

  def count
    count = Meeting.visible.not_templated
      .where(id: agenda_items_linked_to_work_package.select(:meeting_id))
      .count
    render json: { count: }
  end

  def add_work_package_to_meeting_dialog
    respond_with_dialog WorkPackageMeetingsTab::AddWorkPackageToMeetingDialogComponent.new(work_package: @work_package)
  end

  def add_work_package_to_meeting # rubocop:disable Metrics/AbcSize
    call = ::MeetingAgendaItems::CreateService
      .new(user: current_user)
      .call(
        add_work_package_to_meeting_params.merge(
          work_package_id: @work_package.id,
          presenter_id: current_user.id,
          item_type: MeetingAgendaItem::ITEM_TYPES[:work_package],
          meeting_section_id: params[:meeting_agenda_item][:meeting_section_id]
        )
      )

    meeting_agenda_item = call.result

    if call.success?
      set_agenda_items(:upcoming) # always switch back to the upcoming tab after adding the work package to a meeting
      update_index_component
      replace_tab_counter_via_turbo_stream(work_package: @work_package)
    else
      # show errors in form
      update_add_to_meeting_form_component_via_turbo_stream(meeting_agenda_item:, base_errors: call.errors[:base])
    end

    respond_with_turbo_streams
  end

  def refresh_form
    @meeting_agenda_item = MeetingAgendaItem.new(
      meeting: meeting_for(params[:meeting_agenda_item][:meeting_id]),
      notes: params[:meeting_agenda_item][:notes]
    )

    call = MeetingAgendaItems::SetAttributesService.new(
      user: current_user,
      model: @meeting_agenda_item,
      contract_class: EmptyContract
    ).call

    meeting_agenda_item = call.result

    update_via_turbo_stream(
      component: WorkPackageMeetingsTab::AddWorkPackageToMeetingFormComponent.new(
        work_package: @work_package,
        meeting_agenda_item: meeting_agenda_item
      )
    )

    respond_with_turbo_streams
  end

  private

  def set_work_package
    @work_package = @project.work_packages.visible.find(params[:work_package_id])
  end

  def meeting_for(meeting_id)
    # TODO: Should this be scoped to the project?
    Meeting.visible.find(meeting_id)
  end

  def add_work_package_to_meeting_params
    @add_work_package_to_meeting_params ||= params.require(:meeting_agenda_item).permit(:meeting_id, :notes)
  end

  def backlog_id
    meeting_id = add_work_package_to_meeting_params[:meeting_id]
    return if meeting_id.blank?

    meeting = Meeting.visible.find(meeting_id)
    return if meeting.recurring?

    meeting.backlog.id
  end

  def set_agenda_items(direction)
    upcoming_agenda_items_grouped_by_meeting = get_grouped_agenda_items(:upcoming)
    past_agenda_items_grouped_by_meeting = get_grouped_agenda_items(:past)

    @upcoming_meetings_count = upcoming_agenda_items_grouped_by_meeting.count
    @past_meetings_count = past_agenda_items_grouped_by_meeting.count

    @agenda_items_grouped_by_meeting = case direction
                                       when :upcoming
                                         upcoming_agenda_items_grouped_by_meeting
                                       when :past
                                         past_agenda_items_grouped_by_meeting
                                       end
  end

  def get_grouped_agenda_items(direction)
    get_agenda_items_of_work_package(direction).group_by(&:meeting)
  end

  def get_agenda_items_of_work_package(direction)
    agenda_items = agenda_items_linked_to_work_package
        .includes(:meeting)
        .preload(:outcomes)
        .order(sort_clause(direction))

    comparison = direction == :past ? "<" : ">="
    agenda_items.where("meetings.start_time + (interval '1 hour' * meetings.duration) #{comparison} ?", Time.zone.now)
  end

  def agenda_items_linked_to_work_package
    MeetingAgendaItem.visible_linked_to_work_package(current_user, @work_package)
  end

  def sort_clause(direction)
    case direction
    when :upcoming
      "meetings.start_time ASC"
    when :past
      "meetings.start_time DESC"
    else
      raise ArgumentError, "Invalid direction: #{direction}. Must be one of :upcoming or :past."
    end
  end

  def update_index_component
    # update the whole index component as we need to update the counters in the tabbed nav as well
    update_index_component_via_turbo_stream(
      direction: :upcoming,
      agenda_items_grouped_by_meeting: @agenda_items_grouped_by_meeting,
      upcoming_meetings_count: @upcoming_meetings_count,
      past_meetings_count: @past_meetings_count
    )
  end
end
