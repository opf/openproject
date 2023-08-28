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
  before_action :set_meeting_agenda_item,
                except: %i[index new cancel_new create author_autocomplete_index]

  def new
    agenda_item_type = params[:type]&.to_sym
    update_new_component_via_turbo_stream(hidden: false, type: agenda_item_type)
    update_new_button_via_turbo_stream(disabled: true)

    respond_with_turbo_streams
  end

  def cancel_new
    update_new_component_via_turbo_stream(hidden: true)
    update_new_button_via_turbo_stream(disabled: false)

    respond_with_turbo_streams
  end

  def create
    agenda_item_type = params[:type]&.to_sym
    @meeting_agenda_item = @meeting.agenda_items.build(meeting_agenda_item_params)
    @meeting_agenda_item.author = if meeting_agenda_item_params[:author_id].present?
                                    User.find(meeting_agenda_item_params[:author_id])
                                  else
                                    User.current
                                  end

    if @meeting_agenda_item.save
      update_list_via_turbo_stream(form_hidden: false, form_type: agenda_item_type) # enabel continue editing
      update_header_component_via_turbo_stream
    else
      update_new_component_via_turbo_stream(
        hidden: false, meeting_agenda_item: @meeting_agenda_item, type: agenda_item_type
      ) # show errors
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
      update_header_component_via_turbo_stream
    else
      update_item_via_turbo_stream
      update_header_component_via_turbo_stream
    end

    respond_with_turbo_streams
  end

  def destroy
    @meeting_agenda_item.destroy!

    update_list_via_turbo_stream
    update_header_component_via_turbo_stream

    respond_with_turbo_streams
  end

  def drop
    @meeting_agenda_item.insert_at(params[:position].to_i)

    update_list_via_turbo_stream
    update_header_component_via_turbo_stream

    respond_with_turbo_streams
  end

  def move
    case params[:direction]
    when 'top'
      @meeting_agenda_item.move_to_top
    when 'up'
      @meeting_agenda_item.move_higher
    when 'down'
      @meeting_agenda_item.move_lower
    when 'bottom'
      @meeting_agenda_item.move_to_bottom
    end

    update_list_via_turbo_stream
    update_header_component_via_turbo_stream

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
  end

  def set_meeting_agenda_item
    @meeting_agenda_item = MeetingAgendaItem.find(params[:id])
  end

  def meeting_agenda_item_params
    params.require(:meeting_agenda_item).permit(:title, :duration_in_minutes, :description, :author_id, :work_package_id)
  end
end
