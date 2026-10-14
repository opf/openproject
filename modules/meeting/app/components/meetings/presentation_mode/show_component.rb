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
    class ShowComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :meeting, :current_slide

      def initialize(meeting:, sorted_agenda_item_ids:, current_id: nil, current_slide: 1, started_at: nil)
        super()

        @initial = current_id.nil?
        @meeting = meeting
        @project = meeting.project
        @started_at = started_at || Time.current
        @agenda_item_ids = sorted_agenda_item_ids
        @current_id = current_id.nil? ? @agenda_item_ids.first : current_id.to_i
        @current_index = sorted_agenda_item_ids.index(@current_id)
        @current_slide = current_slide
      end

      # Define the interval so it can be overriden through tests
      def check_for_updates_interval
        5_000
      end

      def render?
        @agenda_item_ids.any? && current_item
      end

      def current_item
        return nil if @current_id.nil?

        if defined?(@current_item)
          @current_item
        else
          @current_item = @meeting.agenda_items.find_by(id: @current_id)
        end
      end

      def current_section
        current_item&.meeting_section
      end

      def started_at_param
        @started_at.iso8601
      end
    end
  end
end
