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

module Meetings
  module PresentationNavigation
    extend ActiveSupport::Concern

    included do
      def presentation_started_at
        params[:started_at].present? ? Time.zone.parse(params[:started_at]) : Time.current
      end

      def navigate_from_current_position
        ids = sorted_agenda_item_ids
        current_index = ids.index(@current_id)
        return if current_index.nil?

        current_slides = @meeting.agenda_items.find(@current_id).slides
        @current_slide = current_slides.clamp(@current_slide)

        case params[:action_type]
        when "next"
          navigate_next(ids, current_index, current_slides.count)
        when "previous"
          navigate_previous(ids, current_index)
        end
      end

      def navigate_next(ids, current_index, slide_count)
        if @current_slide < slide_count
          @current_slide += 1
        elsif current_index < ids.size - 1
          @current_id = ids[current_index + 1]
          @current_slide = 1
        end
      end

      def navigate_previous(ids, current_index)
        if @current_slide > 1
          @current_slide -= 1
        elsif current_index.positive?
          @current_id = ids[current_index - 1]
          @current_slide = @meeting.agenda_items.find(@current_id).slides.count
        end
      end

      def presentation_previous_index
        return unless @presentation_mode

        sorted_agenda_item_ids.index(@meeting_agenda_item.id)
      end

      def next_presentation_slide_id(previous_index)
        ids = sorted_agenda_item_ids
        return if ids.empty?

        ids[[previous_index, ids.size - 1].min]
      end

      def advance_presentation_after_move(previous_index, flash_message)
        @started_at = presentation_started_at
        next_id = next_presentation_slide_id(previous_index)

        return exit_presentation_after_move(flash_message) if next_id.nil?

        render_success_flash_message_via_turbo_stream(message: flash_message)
        replace_presentation_show_via_turbo_stream(current_id: next_id)
        respond_with_turbo_streams
      end

      def exit_presentation_after_move(flash_message)
        flash[:notice] = flash_message
        render turbo_stream: turbo_stream.redirect_to(project_meeting_path(@meeting.project, @meeting))
      end
    end
  end
end
