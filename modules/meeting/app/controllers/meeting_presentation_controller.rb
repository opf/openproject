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

class MeetingPresentationController < ApplicationController
  include OpTurbo::ComponentStream
  include Meetings::AgendaComponentStreams
  include Meetings::PresentationComponentStreams

  load_and_authorize_with_permission_in_project :view_meetings

  before_action :find_meeting
  before_action :check_presentable
  before_action :determine_current_position
  before_action :set_started_at
  before_action :find_agenda_item, only: [:check_for_updates]

  layout "meetings/presentation"

  def start
    @meeting.update(state: :in_progress) if @meeting.open? && User.current.allowed_in_project?(:edit_meetings, @meeting.project)
    redirect_to action: :show
  end

  def show; end

  def check_for_updates
    current_reference = @meeting.changed_hash
    if params[:reference] == current_reference
      head :no_content
      return
    end

    update_reference_value(current_reference)
    update_content_via_turbo_stream
  end

  private

  def find_meeting
    @meeting = @project.meetings.visible.find(params[:meeting_id])
  end

  def find_agenda_item
    @meeting_agenda_item = @meeting.agenda_items.find(params[:meeting_agenda_item_id])
  end

  def set_started_at
    @started_at = params[:started_at].present? ? Time.zone.parse(params[:started_at]) : Time.current
  end

  def check_presentable
    if @meeting.agenda_items.empty?
      flash[:warning] = t("meeting.presentation_mode.no_items_flash")
      redirect_to project_meeting_path(@meeting.project, @meeting),
                  status: :see_other
    end
  end

  def determine_current_position
    @current_slide = params.fetch(:slide, 1).to_i
    return if params[:current_id].blank?

    @current_id = params[:current_id].to_i
    navigate_from_current_position if params[:action_type].present?
  end

  def navigate_from_current_position
    current_index = sorted_agenda_item_ids.index(@current_id)
    return if current_index.nil?

    current_slides = @meeting.agenda_items.find(@current_id).slides
    @current_slide = current_slides.clamp(@current_slide)

    case params[:action_type]
    when "next"
      navigate_next(current_index, current_slides.count)
    when "previous"
      navigate_previous(current_index)
    end
  end

  def navigate_next(current_index, slide_count)
    if @current_slide < slide_count
      @current_slide += 1
    elsif current_index < sorted_agenda_item_ids.size - 1
      @current_id = sorted_agenda_item_ids[current_index + 1]
      @current_slide = 1
    end
  end

  def navigate_previous(current_index)
    if @current_slide > 1
      @current_slide -= 1
    elsif current_index.positive?
      @current_id = sorted_agenda_item_ids[current_index - 1]
      @current_slide = @meeting.agenda_items.find(@current_id).slides.count
    end
  end

  def sorted_agenda_item_ids
    @sorted_agenda_item_ids ||= @meeting.sections
                                        .includes(:agenda_items)
                                        .order(:position)
                                        .flat_map { |section| section.agenda_items.order(:position).pluck(:id) }
  end

  helper_method :sorted_agenda_item_ids
end
