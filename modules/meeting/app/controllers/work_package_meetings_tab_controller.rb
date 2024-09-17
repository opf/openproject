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
  include OpTurbo::DialogStreamHelper
  include Meetings::WorkPackageMeetingsTabComponentStreams

  before_action :set_work_package
  before_action :authorize_global

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
    count = get_grouped_agenda_items(:upcoming).count
    render json: { count: }
  end

  def add_work_package_to_meeting_dialog
    respond_with_dialog WorkPackageMeetingsTab::AddWorkPackageToMeetingDialogComponent.new(work_package: @work_package)
  end

  def add_work_package_to_meeting
    call = ::MeetingAgendaItems::CreateService
      .new(user: current_user)
      .call(
        add_work_package_to_meeting_params.merge(
          work_package_id: @work_package.id,
          presenter_id: current_user.id,
          item_type: MeetingAgendaItem::ITEM_TYPES[:work_package]
        )
      )

    meeting_agenda_item = call.result

    if call.success?
      set_agenda_items(:upcoming) # always switch back to the upcoming tab after adding the work package to a meeting

      # update the whole index component as we need to update the counters in the tabbed nav as well
      update_index_component_via_turbo_stream(
        direction: :upcoming,
        agenda_items_grouped_by_meeting: @agenda_items_grouped_by_meeting,
        upcoming_meetings_count: @upcoming_meetings_count,
        past_meetings_count: @past_meetings_count
      )

      replace_tab_counter_via_turbo_stream(work_package: @work_package)

      # TODO: show success message?
    else
      # show errors in form
      update_add_to_meeting_form_component_via_turbo_stream(meeting_agenda_item:, base_errors: call.errors[:base])
    end

    respond_with_turbo_streams
  end

  private

  def set_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
    @project = @work_package.project # required for authorization via before_action
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def add_work_package_to_meeting_params
    params.require(:meeting_agenda_item).permit(:meeting_id, :notes)
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
    agenda_items = MeetingAgendaItem
        .includes(:meeting)
        .where(meeting_id: Meeting.visible(current_user))
        .where(work_package_id: @work_package.id)
        .reorder(sort_clause(direction))

    comparison = direction == :past ? "<" : ">="
    agenda_items.where("meetings.start_time + (interval '1 hour' * meetings.duration) #{comparison} ?", Time.zone.now)
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
end
