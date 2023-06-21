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

class MeetingAgendaTopsController < ApplicationController
  before_action :set_meeting, only: [:new, :index, :create]
  before_action :set_meeting_agenda_top, only: [:show, :edit, :update, :destroy]

  def index
  end

  def show
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          render_agenda_top_via_stream(@meeting_agenda_top)
        ]
      end
    end
  end

  def new
    @meeting_agenda_top = @meeting.agenda_tops.build
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          render_new_form_via_stream(@meeting_agenda_top)
        ]
      end
    end
  end
  
  def create
    @meeting_agenda_top = @meeting.agenda_tops.build(meeting_agenda_top_params)
    @meeting_agenda_top.user = User.current
    if @meeting_agenda_top.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            render_agenda_top_list_via_stream(@meeting),
            render_new_button_via_stream(@meeting)
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            render_new_form_via_stream(@meeting_agenda_top)
          ]
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          render_agenda_top_edit_via_stream(@meeting_agenda_top)
        ]
      end
    end
  end

  def update
    if @meeting_agenda_top.update(meeting_agenda_top_params)
      respond_to do |format|
        format.turbo_stream do
          if @meeting_agenda_top.duration_in_minutes_previously_changed?
            render turbo_stream: [
              render_agenda_top_list_via_stream(@meeting_agenda_top.meeting)
            ]
          else
            render turbo_stream: [
              render_agenda_top_via_stream(@meeting_agenda_top)
            ]
          end
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            render_agenda_top_edit_via_stream(@meeting_agenda_top)
          ]
        end
      end
    end
  end
  
  def destroy
    @meeting_agenda_top.destroy!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          render_agenda_top_list_via_stream(@meeting_agenda_top.meeting)
        ]
      end
    end
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end

  def set_meeting_agenda_top
    @meeting_agenda_top = MeetingAgendaTop.find(params[:id])
  end

  def meeting_agenda_top_params
    params.require(:meeting_agenda_top).permit(:title, :duration_in_minutes)
  end

  # turbo stream helpers

  def render_new_form_via_stream(meeting_agenda_top)
    turbo_stream.replace(
      "new-meeting-agenda-top-form",
      partial: 'meeting_agenda_tops/new_form',
      locals: { meeting_agenda_top: meeting_agenda_top }
    )
  end

  def render_new_button_via_stream(meeting)
    turbo_stream.replace(
      "new-meeting-agenda-top-form",
      partial: 'meeting_agenda_tops/new_button',
      locals: { meeting: meeting }
    )
  end

  def render_agenda_top_list_via_stream(meeting)
    turbo_stream.replace(
      "meeting-agenda-top-list",
      partial: 'meeting_agenda_tops/list',
      locals: { meeting: meeting }
    )
  end

  def render_agenda_top_via_stream(meeting_agenda_top)
    turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(meeting_agenda_top),
      partial: 'meeting_agenda_tops/show',
      locals: { meeting_agenda_top: meeting_agenda_top }
    )
  end

  def render_agenda_top_edit_via_stream(meeting_agenda_top)
    turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(meeting_agenda_top),
      partial: 'meeting_agenda_tops/edit',
      locals: { meeting_agenda_top: meeting_agenda_top }
    )
  end

end
