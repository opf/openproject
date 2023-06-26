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
  before_action :set_meeting
  before_action :set_meeting_agenda_item, except: [:index, :new, :create]

  def new
    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::NewSectionComponent,
        params: { state: :form, meeting: @meeting },
        action: :replace
      }
    )
  end

  def cancel_edit
    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::NewSectionComponent,
        params: { state: :initial, meeting: @meeting },
        action: :replace
      }
    )
  end
  
  def create
    @meeting_agenda_item = @meeting.agenda_items.build(meeting_agenda_item_params)
    @meeting_agenda_item.user = User.current

    if @meeting_agenda_item.save
      respond_with_turbo_stream(
        {
          component: MeetingAgendaItems::NewSectionComponent,
          params: { state: :initial, meeting: @meeting },
          action: :replace
        },
        {
          component: MeetingAgendaItems::ListComponent,
          params: { meeting: @meeting },
          action: :replace
        }
      )
    else
      respond_with_turbo_stream(
        {
          component: MeetingAgendaItems::NewSectionComponent,
          params: { state: :form, meeting: @meeting, meeting_agenda_item: @meeting_agenda_item },
          action: :replace
        }
      )
    end
  end

  def edit
    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::ItemComponent,
        params: { state: :edit, meeting_agenda_item: @meeting_agenda_item },
        action: :replace
      }
    )
  end

  def cancel_edit
    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::ItemComponent,
        params: { state: :initial, meeting_agenda_item: @meeting_agenda_item },
        action: :replace
      }
    )
  end

  def update
    @meeting_agenda_item.update(meeting_agenda_item_params)

    if @meeting_agenda_item.errors.any?
      respond_with_turbo_stream(
        {
          component: MeetingAgendaItems::ItemComponent,
          params: { state: :edit, meeting_agenda_item: @meeting_agenda_item },
          action: :replace
        }
      )
    else
      if @meeting_agenda_item.duration_in_minutes_previously_changed?
        respond_with_turbo_stream(
          {
            component: MeetingAgendaItems::ListComponent,
            params: { meeting: @meeting },
            action: :replace
          }
        )
      else
        respond_with_turbo_stream(
          {
            component: MeetingAgendaItems::ItemComponent,
            params: { state: :initial, meeting_agenda_item: @meeting_agenda_item },
            action: :replace
          }
        )
      end
    end
  end
  
  def destroy
    @meeting_agenda_item.destroy!
    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::ListComponent,
        params: { meeting: @meeting },
        action: :replace
      }
    )
  end

  def drop
    @meeting_agenda_item.insert_at(params[:position].to_i)

    respond_with_turbo_stream(
      {
        component: MeetingAgendaItems::ListComponent,
        params: { meeting: @meeting },
        action: :replace
      }
    )
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:meeting_id])
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = MeetingAgendaItem.find(params[:id])
  end

  def meeting_agenda_item_params
    params.require(:meeting_agenda_item).permit(:title, :duration_in_minutes)
  end

  ###
  # via base controller or concern
  def respond_with_turbo_stream(*args)
    streams = []
    args.each do |value|
      if value.is_a?(Hash)
        if value[:action] == :replace # only replace is supported for now in this prototype
          streams << value[:component].replace_via_turbo_stream(
            view_context: view_context,
            **value[:params]
          )
        end
      else
        streams << value
      end
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: streams
      end
    end
  end
  ###

end
