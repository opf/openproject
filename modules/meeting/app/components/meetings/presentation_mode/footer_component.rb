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
  module PresentationMode
    class FooterComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable

      def initialize(meeting:, sorted_agenda_item_ids:, current_item:, current_slide:, started_at:)
        super()

        @meeting = meeting
        @project = meeting.project
        @current_item = current_item
        @current_slide = current_item.slides.clamp(current_slide)
        @started_at = started_at.iso8601
        @agenda_item_ids = sorted_agenda_item_ids
        @current_index = sorted_agenda_item_ids.index(current_item.id)
      end

      def current_item
        @current_item
      end

      def current_section
        current_item&.meeting_section
      end

      def total_items
        @total_items ||= @agenda_item_ids.size
      end

      def total_slides
        current_item.slides.count
      end

      def has_previous?
        has_previous_item? || @current_slide > 1
      end

      def has_next?
        has_next_item? || @current_slide < total_slides
      end

      def has_previous_item?
        @current_index > 0
      end

      def has_next_item?
        @current_index < total_items - 1
      end

      def navigation_path(action_type)
        project_meeting_presentation_path(@project, @meeting,
                                          current_id: @current_item.id,
                                          slide: @current_slide,
                                          action_type:,
                                          started_at: @started_at)
      end

      def next_item
        return nil unless has_next_item?

        if defined?(@next_item)
          @next_item
        else
          next_id = @agenda_item_ids[@current_index + 1]
          @next_item = @meeting.agenda_items.find_by(id: next_id)
        end
      end

      def previous_item
        return nil unless has_previous_item?

        if defined?(@previous_item)
          @previous_item
        else
          previous_id = @agenda_item_ids[@current_index - 1]
          @previous_item = @meeting.agenda_items.find_by(id: previous_id)
        end
      end

      def next_presenter_changed?
        next_item&.presenter.present? && next_item.presenter != current_item&.presenter
      end

      def previous_presenter_changed?
        previous_item&.presenter.present? && previous_item.presenter != current_item&.presenter
      end

      def progress_text
        if total_items.zero?
          t("meeting.presentation_mode.no_items")
        else
          t("meeting.presentation_mode.total_items", current: @current_index + 1, total: total_items)
        end
      end

      def slide_progress_text
        return if total_slides <= 1

        t("meeting.presentation_mode.slide_progress", current: @current_slide, total: total_slides)
      end

      def running_time
        render(OpPrimer::RelativeTimeComponent.new(datetime: helpers.in_user_zone(@started_at),
                                                   format: :elapsed,
                                                   prefix: nil))
      end
    end
  end
end
