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
  include OpTurbo::ComponentStream
  include AgendaComponentStreams

  before_action :set_meeting
  before_action :set_meeting_agenda_item, except: %i[index new cancel_new create lock unlock close]

  def new
    update_new_section_via_turbo_stream(state: :form)

    respond_with_turbo_streams
  end

  def cancel_new
    update_new_section_via_turbo_stream(state: :initial)

    respond_with_turbo_streams
  end

  def create
    @meeting_agenda_item = @meeting.agenda_items.build(meeting_agenda_item_params)
    @meeting_agenda_item.user = User.current

    if @meeting_agenda_item.save
      update_new_section_via_turbo_stream(state: :form) # enabel continue editing
      update_list_via_turbo_stream
      update_heading_via_turbo_stream
    else
      update_new_section_via_turbo_stream(state: :form, meeting_agenda_item: @meeting_agenda_item) # show errors
    end

    respond_with_turbo_streams
  end

  def edit
    update_item_via_turbo_stream(state: :edit)

    respond_with_turbo_streams
  end

  def cancel_edit
    update_item_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def update
    @meeting_agenda_item.update(meeting_agenda_item_params)

    if @meeting_agenda_item.errors.any?
      update_item_via_turbo_stream(state: :edit) # show errors
    elsif @meeting_agenda_item.duration_in_minutes_previously_changed?
      update_list_via_turbo_stream
      update_heading_via_turbo_stream
    else
      update_item_via_turbo_stream
      update_heading_via_turbo_stream
    end

    respond_with_turbo_streams
  end

  def destroy
    @meeting_agenda_item.destroy!

    update_list_via_turbo_stream
    update_heading_via_turbo_stream

    respond_with_turbo_streams
  end

  def drop
    @meeting_agenda_item.insert_at(params[:position].to_i)

    update_list_via_turbo_stream
    update_heading_via_turbo_stream

    respond_with_turbo_streams
  end

  def lock
    @meeting.agenda_items_locked!

    update_all_via_turbo_stream

    respond_with_turbo_streams
  end

  def unlock
    @meeting.agenda_items_open!

    update_all_via_turbo_stream

    respond_with_turbo_streams
  end

  def close
    @meeting.agenda_items_closed!

    update_all_via_turbo_stream

    respond_with_turbo_streams
  end

  def edit_issue_resolution
    update_via_turbo_stream(
      component: MeetingAgendaItems::ItemComponent::IssueResolutionComponent.new(issue: @meeting_agenda_item.work_package_issue,
                                                                                 meeting_agenda_item: @meeting_agenda_item,
                                                                                 state: :edit)
    )

    respond_with_turbo_streams
  end

  def cancel_edit_issue_resolution
    update_via_turbo_stream(
      component: MeetingAgendaItems::ItemComponent::IssueResolutionComponent.new(issue: @meeting_agenda_item.work_package_issue,
                                                                                 meeting_agenda_item: @meeting_agenda_item,
                                                                                 state: :initial)
    )

    respond_with_turbo_streams
  end

  def resolve_issue
    @issue = @meeting_agenda_item.work_package_issue
    if @issue.resolve(User.current, issue_params[:resolution])
      update_item_via_turbo_stream
    else
      update_via_turbo_stream(
        component: MeetingAgendaItems::ItemComponent::IssueResolutionComponent.new(issue: @issue,
                                                                                   meeting_agenda_item: @meeting_agenda_item,
                                                                                   state: :edit)
      )
    end
    respond_with_turbo_streams
  end

  def reopen_issue
    if @issue.reopen # keep the former resolution in place
      redirect_to open_work_package_issues_path(@work_package)
    end
  end

  def edit_notes
    update_via_turbo_stream(
      component: MeetingAgendaItems::ItemComponent::NotesComponent.new(
        meeting_agenda_item: @meeting_agenda_item,
        state: :edit
      )
    )

    respond_with_turbo_streams
  end

  def cancel_edit_notes
    update_via_turbo_stream(
      component: MeetingAgendaItems::ItemComponent::NotesComponent.new(
        meeting_agenda_item: @meeting_agenda_item,
        state: :initial
      )
    )

    respond_with_turbo_streams
  end

  def save_notes
    if @meeting_agenda_item.update(details: meeting_agenda_item_params[:details])
      update_item_via_turbo_stream
    else
      update_via_turbo_stream(
        component: MeetingAgendaItems::ItemComponent::NotesComponent.new(
          meeting_agenda_item: @meeting_agenda_item,
          state: :edit
        )
      )
    end
    respond_with_turbo_streams
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = MeetingAgendaItem.find(params[:id])
  end

  def meeting_agenda_item_params
    params.require(:meeting_agenda_item).permit(:title, :duration_in_minutes, :work_package_issue_id, :details, :user_id)
  end

  def issue_params
    params.require(:work_package_issue).permit(:resolution, :resolved_by_id)
  end
end
